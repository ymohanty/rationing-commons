from openpyxl import *
import sys
import os.path
import pandas as pd
from multiprocessing import Pool
from fuzzywuzzy import fuzz
import numpy as np


def main(args):
    # Set up project level paths
    if len(args) < 2:
        if sys.platform == "darwin" or sys.platform == "linux" or sys.platform == "linux2":
            project_root = os.path.expanduser("~") + "/Dropbox/replication_rationing_commons/"
        elif sys.platform == "win32":
            project_root = os.path.expanduser("~") + "\\Dropbox\\replication_rationing_commons\\"
        else:
            print("OS %s not supported" % sys.platform)
            exit(-1)
    else:
        project_root = args[1]

    # Generate data path
    soil_data_path = project_root + os.path.join("data", "soil", "raw")

    # Output path
    output_path = project_root + os.path.join("data", "soil", "clean")

    # Set up file paths
    paths = [soil_data_path + "/village_wise_jhalawar_2016-17.xlsx",
             soil_data_path + "/village_wise_bundi_2017-18.xlsx",
             soil_data_path + "/village_wise_alwar_2017-18.xlsx",
             soil_data_path + "/village_wise_jaipur_2017-18.xlsx"]

    # Create dataframes in parallel and append them together into one dataframe.
    pool = Pool(4)
    soil_data_worksheets = [workbook["NSVW_Total"] for workbook in pool.map(load_workbook, paths)]
    soil_data_frame = pd.concat([construct_data_frame(ws, district_name) for ws, district_name in
                                 zip(soil_data_worksheets, ["Jhalawar", "Bundi", "Alwar", "Jaipur"])])
    soil_data_frame["id"] = range(soil_data_frame.shape[0])

    # Generate variable labels
    labels = dict(AS_pH="Num. Acid Sulphate", SrAC_pH="Num. strongly acidic", HAc_pH="Num. highly acidic",
                  MAc_pH="Num. moderately acidic", SLAc_pH="Num. slightly acidic", N_pH="Num. neutral acidity",
                  MAl_pH="Num. moderately alkaline", SlAl_pH="Num. strongly alkaline", Tot_pH="Total farmers reported")
    verylow_veryhigh = ["OC", "N", "P", "K"]
    sufficient_deficient = ["S", "Zn", "Fe", "Cu", "Mn", "B"]
    symbol_to_name = dict(OC="OC", N="Nitrogen", P="Phosphorus", K="Potassium", S="Suplhur", Zn="Zinc", Fe="Iron",
                          Cu="Copper", Mn="Manganese", B="Boron")
    for var in verylow_veryhigh:
        labels["VL_" + var] = "Num. very low " + symbol_to_name[var]
        labels["L_" + var] = "Num. low " + symbol_to_name[var]
        labels["VH_" + var] = "Num. very high " + symbol_to_name[var]
        labels["H_" + var] = "Num. high " + symbol_to_name[var]
        labels["M_" + var] = "Num. medium" + symbol_to_name[var]
        labels["Tot_" + var] = "Total num. reporting " + symbol_to_name[var]

    for var in sufficient_deficient:
        labels["S_" + var] = "Num. sufficient " + symbol_to_name[var]
        labels["D_" + var] = "Num. deficient " + symbol_to_name[var]
        labels["Tot_" + var] = "Total num. reporting " + symbol_to_name[var]

    # Keep correct blocks
    soil_data_frame = soil_data_frame.loc[
        soil_data_frame["block"].isin(["Dag", "Kotputli", "Nainwa", "Mandawar", "Bansur", "Hindoli"])]

    # ~~~~~~~~~~~ Cleaning village names ~~~~~~~~~~~~

    # Dictionary to track duplicate matches
    dup_dict = {}

    # Open relevant files
    farmer_survey = pd.read_stata(project_root + os.path.join("data", "farmer_survey", "clean",
                                                              "baseline_survey_selected_variables_crop_level.dta"))

    # Get correct spellings for names
    correct_district_names = sorted(list(set(soil_data_frame["district"].tolist())))
    correct_block_names = sorted(list(set(soil_data_frame["block"].tolist())))

    # Corrected district and block names for baseline data
    corrected_district_names = list(
        map(lambda x: clean_names(x, correct_district_names), farmer_survey["district"].tolist()))
    corrected_block_names = list(map(lambda x: clean_names(x, correct_block_names), farmer_survey["block"].tolist()))

    # Correct village name within district-block cluster
    corrected_village_names = list(map(lambda x: clean_names(x, get_correct_names(x, farmer_survey["village"].tolist(),
                                                                                  corrected_district_names,
                                                                                  corrected_block_names,
                                                                                  soil_data_frame), dup_dict),
                                       farmer_survey["village"].tolist()))

    # Add correct names to temporary farmer survey dataframe
    temp_farmer_survey = pd.concat([farmer_survey["f_id"], farmer_survey["crop"], pd.Series(corrected_district_names),
                                    pd.Series(corrected_block_names), pd.Series(corrected_village_names)], axis=1,
                                   keys=["f_id", "crop", "corrected_district_names",
                                         "corrected_block_names", "corrected_village_names"])

    # Add original and corrected village names for inspection
    village_name_df = pd.DataFrame(
        data={"original": farmer_survey["village"].tolist(), "new": corrected_village_names}).drop_duplicates()
    village_name_df.to_csv(project_root + os.path.join("data", "farmer_survey", "clean",
                                                       "village_name_comparison.csv"), index=False)

    # Data frame for duplicate matches
    dup_dict = frame_from_dict(dup_dict)
    dup_dict.to_excel(project_root + os.path.join("data","farmer_survey","clean","duplicate_matches.xlsx"),index=False)


    # Create Stata files
    temp_farmer_survey.to_stata(project_root + os.path.join("data", "farmer_survey", "clean",
                                                            "temp_farmer_survey.dta"), write_index=False)
    soil_data_frame.to_stata(output_path + "/soil_controls.dta", write_index=False, variable_labels=labels)


def construct_data_frame(ws, district_name):
    """

    Very low-Very high scheme: OC, N, P, K
    Sufficient-Deficient: S, Zn, Fe, Cu, Mn, B


    """
    # Output proto-dataframe
    df = {}

    # All variables, very low-very high scheme, sufficient deficient scheme
    vars = ["pH", "EC", "OC", "N", "P", "K", "S", "Zn", "Fe", "Cu", "Mn", "B"]
    verylow_veryhigh = ["OC", "N", "P", "K"]
    sufficient_deficient = ["S", "Zn", "Fe", "Cu", "Mn", "B"]

    # Get blocks, villages
    ph_data = construct_raw_column(ws, "pH")
    blocks = ph_data["block"]
    villages = ph_data["village"]

    # Get all the levels from each variable
    for var in vars:
        if var == "pH":
            level_names = dict(AS=0, SrAC=1, HAc=2, MAc=3, SLAc=4, N=5, MAl=6, SlAl=7, Tot=8)
            get_variable_levels(df, ws, var, level_names)
        elif var in verylow_veryhigh:
            level_names = dict(VL=0, L=1, VH=2, H=3, M=4, Tot=5)
            get_variable_levels(df, ws, var, level_names)
        elif var in sufficient_deficient:
            level_names = dict(S=0, D=1, Tot=2)
            get_variable_levels(df, ws, var, level_names)
        else:
            continue

    # Put identifier variables into dataframe
    df["block"] = blocks
    df["village"] = villages
    df["district"] = len(villages) * [district_name]
    return pd.DataFrame.from_dict(df)


# Return all the levels for each variable as a separate variable
# in wide format
def get_variable_levels(df, ws, var, level_names):
    col = construct_raw_column(ws, var)
    level_components = [cell.split("\n") for cell in col[var]]
    for key in level_names.keys():
        varname = key + "_" + var
        df[varname] = [int(component[level_names[key]].split("-")[1].strip()) for component in level_components]


def construct_raw_column(ws, var):
    # Generate variable position keymap
    var_dict = dict(pH=3, EC=4, OC=7, N=8, P=9, K=10, S=11, Zn=12, Fe=13, Cu=15, Mn=16, B=17)

    # Proto-dataframe
    df = {"block": [], "village": [], var: []}

    # Iterate over all the rows in the worksheet and add variables
    # to the proto-dataframe
    values = [row for row in ws.values]
    for row_num in range(5, len(values)):

        # Check for block name, or village name, block totals
        # Append data for key (say pH) to the proto-dataframe
        if values[row_num][2] is None:
            continue
        elif values[row_num][2].split(" ")[0] == "Total":
            continue
        elif values[row_num][2].split(" ")[0] == "Block/Mandal:":
            df["block"].append(values[row_num][2].split(":")[1].strip())
        elif values[row_num][2].split(" ")[0] == "Village:":
            df["village"].append(values[row_num][2].split(":")[1].strip())
        else:
            df[var].append(values[row_num][var_dict[var]])

            # We copy the block value forward if the next row defines village data
            # for the same block
            try:
                if values[row_num + 1][2].split(" ")[0] == "Village:":
                    df["block"].append(df["block"][-1])
            except AttributeError as ae:
                continue

    return df


# Spell correct a list of names given a different list of names
def clean_names(word, correct_names, dup_dict = None, thresh=70, fun=fuzz.token_set_ratio):
    matches = list(map(lambda x: fun(x, word) if fun(x, word) > thresh else -1 * np.infty, correct_names))
    max = np.max(matches)
    best_match = correct_names[matches.index(max)]
    match_list = [correct_names[index] for index, value in enumerate(matches) if value == max]
    if max > 0 and best_match != "None":
        if isinstance(dup_dict,dict) and len(match_list) > 1:
            dup_dict[word] = match_list

        return best_match
    else:
        return "None"


def get_correct_names(village, survey_village_names, corrected_district_names, corrected_block_names, soil_data_frame):
    # Construct soil district, block and village names
    soil_names = list(zip(soil_data_frame["district"].tolist(), soil_data_frame["block"].tolist(),
                          soil_data_frame["village"].tolist()))

    # Get the indices of the village in the survey data
    indices = [index for index, name in enumerate(survey_village_names) if name == village]
    village_in_districts = [corrected_district_names[i] for i in indices]
    village_in_blocks = [corrected_block_names[i] for i in indices]

    # Construct a list of possible villages based on a match on district and block
    candidate_villages = sorted(list(
        set([name[2] for name in soil_names if name[0] in village_in_districts and name[1] in village_in_blocks])))

    # Check if list is empty due to bad cleaning of the district and block names
    if not candidate_villages:
        candidate_villages = ["None"]

    return candidate_villages

# Construct a dataframe from a dictionary with unequal length
# values
def frame_from_dict(input_dict):

    # Find average length of multiple matches
    numkeys = len(input_dict)
    avg_num_matches = np.mean([len(v) for k,v in input_dict.items()])
    std_num_matches = np.std([len(v) for k,v in input_dict.items()])
    print(f'The total number of villages in the farmer survey with with multiple matches in the soil data is {numkeys}, '
          f'the average number of matches for this set is {avg_num_matches:.2f} with a standard deviation of {std_num_matches:.2f}')

    # Construct frame from input dictionary
    frame = pd.DataFrame(dict([(k,pd.Series(v)) for k,v in input_dict.items()]))
    return frame



if __name__ == '__main__':
    main(sys.argv)
