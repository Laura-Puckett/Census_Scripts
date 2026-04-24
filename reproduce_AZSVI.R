# This script follows methods detailed in the Technical Data Documentation for the Arizona Social Vulnerability Index (AZSVI). 
# The purpose is to recreate some fields from the AZSVI using newer census data (2020-2024). 

library(tidycensus); library(dplyr)

# ------------------------------------------------#
# Section 1. Metadata
# ------------------------------------------------#

# AZSVI Documentation: https://www.azdhs.gov/documents/director/health-equity/azsvi-technical-data-documentation.pdf

# Census Documentation for Variable Names and Descriptions
  # https://api.census.gov/data/2024/acs/acs5/profile/groups/DP02.html
  # https://api.census.gov/data/2024/acs/acs5/profile/groups/DP03.html
  # https://api.census.gov/data/2024/acs/acs5/profile/groups/DP04.html
  # https://api.census.gov/data/2024/acs/acs5/profile/groups/DP05.html
  # https://api.census.gov/data/2024/acs/acs5/subject/groups/S0101.html
  # https://api.census.gov/data/2024/acs/acs5/subject/groups/S0601.html
  # https://api.census.gov/data/2024/acs/acs5/subject/groups/S1701.html
  # https://api.census.gov/data/2024/acs/acs5/subject/groups/S2201.html
  # https://api.census.gov/data/2024/acs/acs5/subject/groups/S2503.html
  # https://api.census.gov/data/2024/acs/acs5/subject/groups/S2701.html
  # https://api.census.gov/data/2024/acs/acs5/subject/groups/S2801.html
  # https://api.census.gov/data/2024/acs/acs5/groups/B06009.html
  # https://api.census.gov/data/2024/acs/acs5/groups/B16005.html
  # https://api.census.gov/data/2024/acs/acs5/groups/B26001.html

  # Suffixes in Census Variables:
    # Estimates (E)
    # Percent Estimates (PE)
    # Margin of Error of Estimate (ME)
    # Margin of Error of Percent (PM)
    # * Exceptions are the subject tables where estimates are denoted by "Percent" within the variable description.

# ------------------------------------------------#
# Section 2. Download Data
# ------------------------------------------------#
census_variables <- c(
  # SVI
  "DP02_0001E", "DP02_0001M", # HOUSEHOLDS BY TYPE!!Total households
  "DP02_0007PE", # HOUSEHOLDS BY TYPE!!Total households!!Male householder, no spouse/partner present!!With children of the householder under 18 years
  "DP02_0072E", "DP02_0072M", "DP02_0072PE", "DP02_0072PM", # DISABILITY STATUS OF THE CIVILIAN NONINSTITUTIONALIZED POPULATION!!Total Civilian Noninstitutionalized Population!!With a disability
  "DP02_0007E", "DP02_0007M", # HOUSEHOLDS BY TYPE!!Total households!!Male householder, no spouse/partner present!!With children of the householder under 18 years
  "DP02_0011E", "DP02_0011M", "DP02_0011PE", # HOUSEHOLDS BY TYPE!!Total households!!Female householder, no spouse/partner present!!With children of the householder under 18 years
  "DP03_0005E", "DP03_0005M", # EMPLOYMENT STATUS!!Population 16 years and over!!In labor force!!Civilian labor force!!Unemployed
  "DP03_0009PE", "DP03_0009PM", # EMPLOYMENT STATUS!!Civilian labor force!!Unemployment Rate
  "DP04_0001E", "DP04_0001M", # HOUSING OCCUPANCY!!Total housing units
  "DP04_0002E", "DP04_0002M", # HOUSING OCCUPANCY!!Total housing units!!Occupied housing units
  "DP04_0012E", "DP04_0012M", "DP04_0012PE", # UNITS IN STRUCTURE!!Total housing units!!10 to 19 units
  "DP04_0013E", "DP04_0013M", "DP04_0013PE", # UNITS IN STRUCTURE!!Total housing units!!20 or more units
  "DP04_0014E", "DP04_0014M", "DP04_0014PE", "DP04_0014PM", # UNITS IN STRUCTURE!!Total housing units!!Mobile home
  "DP04_0078E", "DP04_0078M", "DP04_0078PE", # OCCUPANTS PER ROOM!!Occupied housing units!!1.01 to 1.50
  "DP04_0079E", "DP04_0079M", "DP04_0079PE", # OCCUPANTS PER ROOM!!Occupied housing units!!1.51 or more
  "DP04_0058E", "DP04_0058M", "DP04_0058PE", "DP04_0058PM", # VEHICLES AVAILABLE!!Occupied housing units!!No vehicles available
  "DP05_0001E", "DP05_0001M", # Estimate!!SEX AND AGE!!Total population
  "DP05_0019E", "DP05_0019M", "DP05_0019PE", "DP05_0019PM", # SEX AND AGE!!Total population!!Under 18 years
  "DP05_0096E", "DP05_0096M", "DP05_0096PE", "DP05_0096PM", # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!White alone
  "S0101_C01_030E", "S0101_C01_030M", # Total!!Total population!!SELECTED AGE CATEGORIES!!65 years and over
  "S0101_C02_030E", "S0101_C02_030M",  # Percent!!Total population!!SELECTED AGE CATEGORIES!!65 years and over
  "S0601_C01_001E", "S0601_C01_001M", # Total!!Total population
  "S0601_C01_033E", "S0601_C01_033M", # Total!!EDUCATIONAL ATTAINMENT!!Population 25 years and over!!Less than high school graduate
  "S1701_C01_001E", "S1701_C01_001M", # Total!!Population for whom poverty status is determined
  "S1701_C01_040E", "S1701_C01_040M", # Total!!Population for whom poverty status is determined!!ALL INDIVIDUALS WITH INCOME BELOW THE FOLLOWING POVERTY RATIOS!!150 percent of poverty level
  "S2503_C01_001E", "S2503_C01_001M", # Occupied housing units!!Occupied housing units
  "S2503_C01_028E", "S2503_C01_028M", # Occupied housing units!!Occupied housing units!!MONTHLY HOUSING COSTS AS A PERCENTAGE OF HOUSEHOLD INCOME IN THE PAST 12 MONTHS!!Less than $20,000!!30 percent or more
  "S2503_C01_032E", "S2503_C01_032M", # Occupied housing units!!Occupied housing units!!MONTHLY HOUSING COSTS AS A PERCENTAGE OF HOUSEHOLD INCOME IN THE PAST 12 MONTHS!!$20,000 to $34,999!!30 percent or more
  "S2503_C01_036E", "S2503_C01_036M", # Occupied housing units!!Occupied housing units!!MONTHLY HOUSING COSTS AS A PERCENTAGE OF HOUSEHOLD INCOME IN THE PAST 12 MONTHS!!$35,000 to $49,999!!30 percent or more
  "S2503_C01_040E", "S2503_C01_040M", # Occupied housing units!!Occupied housing units!!MONTHLY HOUSING COSTS AS A PERCENTAGE OF HOUSEHOLD INCOME IN THE PAST 12 MONTHS!!$50,000 to $74,999!!30 percent or more	
  "S2701_C04_001E", "S2701_C04_001M", # Uninsured!!Civilian noninstitutionalized population
  "S2701_C05_001E", "S2701_C05_001M", # Percent Uninsured!!Civilian noninstitutionalized population
  "B06009_002E", "B06009_002M", # Total:!!Less than high school graduate
  "B16005_001E", "B16005_001M", # Total (Concept: Nativity by Language Spoken at Home by Ability to Speak English for the Population 5 Years and Over)
  "B16005_007E", "B16005_007M", # Total:!!Native:!!Speak Spanish:!!Speak English "not well"
  "B16005_008E", "B16005_008M", # Total:!!Native:!!Speak Spanish:!!Speak English "not at all"
  "B16005_012E", "B16005_012M", # Total:!!Native:!!Speak other Indo-European languages:!!Speak English "not well"
  "B16005_013E", "B16005_013M", # Total:!!Native:!!Speak other Indo-European languages:!!Speak English "not at all"
  "B16005_017E", "B16005_017M", # Total:!!Native:!!Speak Asian and Pacific Island languages:!!Speak English "not well"
  "B16005_018E", "B16005_018M", # Total:!!Native:!!Speak Asian and Pacific Island languages:!!Speak English "not at all"
  "B16005_022E", "B16005_022M", # Total:!!Native:!!Speak other languages:!!Speak English "not well"
  "B16005_023E", "B16005_023M", # Total:!!Native:!!Speak other languages:!!Speak English "not at all"
  "B16005_029E", "B16005_029M", # Total:!!Foreign born:!!Speak Spanish:!!Speak English "not well"
  "B16005_030E", "B16005_030M", # Total:!!Foreign born:!!Speak Spanish:!!Speak English "not at all"
  "B16005_034E", "B16005_034M", # Total:!!Foreign born:!!Speak other Indo-European languages:!!Speak English "not well"
  "B16005_035E", "B16005_035M", # Total:!!Foreign born:!!Speak other Indo-European languages:!!Speak English "not at all"
  "B16005_039E", "B16005_039M", # Total:!!Foreign born:!!Speak Asian and Pacific Island languages:!!Speak English "not well"
  "B16005_040E", "B16005_040M", # Total:!!Foreign born:!!Speak Asian and Pacific Island languages:!!Speak English "not at all"
  "B16005_044E", "B16005_044M", # Total:!!Foreign born:!!Speak other languages:!!Speak English "not well"
  "B16005_045E", "B16005_045M", # Total:!!Foreign born:!!Speak other languages:!!Speak English "not at all"
  "B26001_001E", "B26001_001M", # Total (Concept: Group Quarters Population)
  
  # Arizona Theme
  "DP04_0142E", "DP04_0142M", "DP04_0142PE", "DP04_0142PM", # GROSS RENT AS A PERCENTAGE OF HOUSEHOLD INCOME (GRAPI)!!Occupied units paying rent (excluding units where GRAPI cannot be computed)!!35.0 percent or more
  "S2201_C03_001E", "S2201_C03_001M", "S2201_C04_001E", "S2201_C04_001M", # Households receiving food stamps/SNAP!!Households
  "S2801_C02_005E", "S2801_C02_005M" # Percent!!Total households!!TYPES OF COMPUTER!!Has one or more types of computing devices:!!Smartphone
)

acs_data <- get_acs(geography = "tract", variables = census_variables, year = 2024, output = "wide", state = "AZ", county = "Coconino", geometry = TRUE, survey = "acs5", show_call = TRUE, keep_geo_vars = TRUE)

# ------------------------------------------------#
# Section 2. Calculate Derived Variables
# ------------------------------------------------#

svi_results <- acs_data |>
  mutate(
    # -----------------------------
    # Base estimates and MOEs
    # -----------------------------
    E_TOTPOP  = S0601_C01_001E, 
    M_TOTPOP  = S0601_C01_001M,
    E_HU      = DP04_0001E, 
    M_HU      = DP04_0001M,
    E_HH      = DP02_0001E, 
    M_HH      = DP02_0001M,
    E_POV150  = S1701_C01_040E,
    M_POV150  = S1701_C01_040M,
    EP_POV150 = (E_POV150 / S1701_C01_001E) * 100,
    MP_POV150 = (sqrt(M_POV150^2 - ((EP_POV150 / 100)^2 * S1701_C01_001M^2)) / S1701_C01_001E) * 100,
    E_UNEMP   = DP03_0005E, 
    M_UNEMP   = DP03_0005M,
    EP_UNEMP  = DP03_0009PE,
    MP_UNEMP  = DP03_0009PM,
    E_HBURD   = S2503_C01_028E + S2503_C01_032E + S2503_C01_036E + S2503_C01_040E,
    M_HBURD   = sqrt(S2503_C01_028M^2 + S2503_C01_032M^2 + S2503_C01_036M^2 + S2503_C01_040M^2),
    EP_HBURD  = (E_HBURD / S2503_C01_001E) * 100,
    MP_HBURD  = (sqrt(M_HBURD^2 - ((EP_HBURD / 100)^2 * S2503_C01_001M^2)) / S2503_C01_001E) * 100,
    E_NOHSDP  = B06009_002E,
    M_NOHSDP  = B06009_002M,
    EP_NOHSDP = S0601_C01_033E, 
    MP_NOHSDP = S0601_C01_033M,
    E_UNINSUR = S2701_C04_001E,
    M_UNINSUR = S2701_C04_001M,
    EP_UNINSUR = S2701_C05_001E,
    MP_UNINSUR = S2701_C05_001M,
    E_AGE65   = S0101_C01_030E,
    M_AGE65   = S0101_C01_030M,
    EP_AGE65  = S0101_C02_030E,
    MP_AGE65  = S0101_C02_030M,
    E_AGE17   = DP05_0019E, 
    M_AGE17   = DP05_0019M,
    EP_AGE17  = DP05_0019PE,
    MP_AGE17  = DP05_0019PM,
    E_DISABL  = DP02_0072E, 
    M_DISABL  = DP02_0072M,
    EP_DISABL = DP02_0072PE,
    MP_DISABL = DP02_0072PM,
    E_SNGPNT  = DP02_0007E + DP02_0011E, 
    M_SNGPNT  = sqrt(DP02_0007M^2 + DP02_0011M^2),
    EP_SNGPNT = DP02_0007PE + DP02_0011PE,
    MP_SNGPNT = (sqrt(M_SNGPNT^2 - ((EP_SNGPNT / 100)^2 * M_HH^2)) / E_HH) * 100,
    E_LIMENG  = B16005_007E + B16005_008E + B16005_012E + B16005_013E + 
      B16005_017E + B16005_018E + B16005_022E + B16005_023E + 
      B16005_029E + B16005_030E + B16005_034E + B16005_035E + 
      B16005_039E + B16005_040E + B16005_044E + B16005_045E, 
    M_LIMENG  = sqrt(B16005_007M^2 + B16005_008M^2 + B16005_012M^2 + B16005_013M^2 +
                       B16005_017M^2 + B16005_018M^2 + B16005_022M^2 + B16005_023M^2 +
                       B16005_029M^2 + B16005_030M^2 + B16005_034M^2 + B16005_035M^2 +
                       B16005_039M^2 + B16005_040M^2 + B16005_044M^2 + B16005_045M^2),
    EP_LIMENG = (E_LIMENG / B16005_001E) * 100,
    MP_LIMENG = (sqrt(M_LIMENG^2 - ((EP_LIMENG / 100)^2 * B16005_001M^2)) / B16005_001E) * 100,
    E_MINRTY  = DP05_0001E - DP05_0096E, 
    M_MINRTY  = sqrt(M_TOTPOP^2 + DP05_0096M^2),
    EP_MINRTY = 100.0 - DP05_0096PE,
    MP_MINRTY = (sqrt(M_MINRTY^2 - ((EP_MINRTY / 100)^2 * M_TOTPOP^2)) / E_TOTPOP) * 100,
    E_MUNIT   = DP04_0012E + DP04_0013E,
    M_MUNIT   = sqrt(DP04_0012M^2 + DP04_0013M^2),
    EP_MUNIT  = DP04_0012PE + DP04_0013PE,
    MP_MUNIT  = (sqrt(M_MUNIT^2 - ((EP_MUNIT / 100)^2 * M_HU^2)) / E_HU) * 100,
    E_MOBILE  = DP04_0014E, 
    M_MOBILE  = DP04_0014M,
    EP_MOBILE = DP04_0014PE,
    MP_MOBILE = DP04_0014PM,
    E_CROWD   = DP04_0078E + DP04_0079E,
    M_CROWD   = sqrt(DP04_0078M^2 + DP04_0079M^2),
    EP_CROWD  = DP04_0078PE + DP04_0079PE,
    MP_CROWD  = (sqrt(M_CROWD^2 - ((EP_CROWD / 100)^2 * DP04_0002M^2)) / DP04_0002E) * 100,
    E_NOVEH   = DP04_0058E, 
    M_NOVEH   = DP04_0058M,
    EP_NOVEH  = DP04_0058PE,
    MP_NOVEH  = DP04_0058PM,
    E_GROUPQ  = B26001_001E,
    M_GROUPQ  = B26001_001M,
    EP_GROUPQ = (E_GROUPQ / E_TOTPOP) * 100,
    MP_GROUPQ = (sqrt(M_GROUPQ^2 - ((EP_GROUPQ / 100)^2 * M_TOTPOP^2)) / E_TOTPOP) * 100,
    
    # -----------------------------
    # Arizona Theme (additional fields)
    # -----------------------------
    E_GRAPI   = DP04_0142E, 
    M_GRAPI   = DP04_0142M,
    EP_GRAPI  = DP04_0142PE,
    MP_GRAPI = DP04_0142PM,
    E_SNAP    = S2201_C03_001E,
    M_SNAP    = S2201_C03_001M,
    EP_SNAP   = S2201_C04_001E,
    MP_SNAP   = S2201_C04_001M,
    EP_NO_SMARTPH = 100.0 - S2801_C02_005E,
    MP_NO_SMARTPH = S2801_C02_005M,
    E_DENSITY = S0601_C01_001E / (ALAND * 3.86102e-7), 
  )


# ------------------------------------------------#
# Section 2. Relabel and Write Output
# ------------------------------------------------#
var_labels <- c(
  "E_TOTPOP"      = "Population estimate, 2020-2024 ACS",
  "M_TOTPOP"      = "Population estimate MOE, 2020-2024 ACS",
  "E_HU"          = "Housing units estimate, 2020-2024 ACS",
  "M_HU"          = "Housing units estimate MOE, 2020-2024 ACS",
  "E_HH"          = "Households estimate, 2020-2024 ACS",
  "M_HH"          = "Households estimate MOE, 2020-2024 ACS",
  "E_POV150"      = "Persons below 150% poverty estimate, 2020-2024 ACS",
  "M_POV150"      = "Persons below 150% poverty estimate MOE, 2020-2024 ACS",
  "E_UNEMP"       = "Civilian (age 16+) unemployed estimate, 2020-2024 ACS",
  "M_UNEMP"       = "Civilian (age 16+) unemployed estimate MOE, 2020-2024 ACS",
  "E_HBURD"       = "Housing cost-burdened occupied housing units (<$75k income, 30%+ of income) estimate",
  "M_HBURD"       = "Housing cost-burdened occupied housing units (<$75k income, 30%+ of income) MOE",
  "E_NOHSDP"      = "Persons (age 25+) with no high school diploma estimate",
  "M_NOHSDP"      = "Persons (age 25+) with no high school diploma estimate MOE",
  "E_UNINSUR"     = "Uninsured in the civilian noninstitutionalized population estimate",
  "M_UNINSUR"     = "Uninsured in the civilian noninstitutionalized population estimate MOE",
  "E_AGE65"       = "Persons aged 65 and older estimate",
  "M_AGE65"       = "Persons aged 65 and older estimate MOE",
  "E_AGE17"       = "Persons aged 17 and younger estimate",
  "M_AGE17"       = "Persons aged 17 and younger estimate MOE",
  "E_DISABL"      = "Civilian noninstitutionalized population with a disability estimate",
  "M_DISABL"      = "Civilian noninstitutionalized population with a disability estimate MOE",
  "E_SNGPNT"      = "Single-parent household with children under 18 estimate",
  "M_SNGPNT"      = "Single-parent household with children under 18 estimate MOE",
  "E_LIMENG"      = "Persons (age 5+) who speak English less than well estimate",
  "M_LIMENG"      = "Persons (age 5+) who speak English less than well estimate MOE",
  "E_MINRTY"      = "Minority population estimate",
  "M_MINRTY"      = "Minority population estimate MOE",
  "E_MUNIT"       = "Housing in structures with 10 or more units estimate",
  "M_MUNIT"       = "Housing in structures with 10 or more units estimate MOE",
  "E_MOBILE"      = "Mobile homes estimate",
  "M_MOBILE"      = "Mobile homes estimate MOE",
  "E_CROWD"       = "Occupied housing units with more people than rooms estimate",
  "M_CROWD"       = "Occupied housing units with more people than rooms estimate MOE",
  "E_NOVEH"       = "Households with no vehicle available estimate",
  "M_NOVEH"       = "Households with no vehicle available estimate MOE",
  "E_GROUPQ"      = "Persons in group quarters estimate",
  "M_GROUPQ"      = "Persons in group quarters estimate MOE",
  "EP_POV150"     = "Percentage of persons below 150% poverty",
  "MP_POV150"     = "Percentage of persons below 150% poverty MOE",
  "EP_UNEMP"      = "Unemployment Rate",
  "MP_UNEMP"      = "Unemployment Rate MOE",
  "EP_HBURD"      = "Percentage of housing units with housing cost burden",
  "MP_HBURD"      = "Percentage of housing units with housing cost burden MOE",
  "EP_NOHSDP"     = "Percentage of persons with no high school diploma",
  "MP_NOHSDP"     = "Percentage of persons with no high school diploma MOE",
  "EP_UNINSUR"    = "Percentage uninsured",
  "MP_UNINSUR"    = "Percentage uninsured MOE",
  "EP_AGE65"      = "Percentage of persons aged 65 and older",
  "MP_AGE65"      = "Percentage of persons aged 65 and older MOE",
  "EP_AGE17"      = "Percentage of persons aged 17 and younger",
  "MP_AGE17"      = "Percentage of persons aged 17 and younger MOE",
  "EP_DISABL"     = "Percentage of persons with a disability",
  "MP_DISABL"     = "Percentage of persons with a disability MOE",
  "EP_SNGPNT"     = "Percentage of single-parent households",
  "MP_SNGPNT"     = "Percentage of single-parent households MOE",
  "EP_LIMENG"     = "Percentage of persons who speak English less than well",
  "MP_LIMENG"     = "Percentage of persons who speak English less than well MOE",
  "EP_MINRTY"     = "Percentage minority",
  "MP_MINRTY"     = "Percentage minority MOE",
  "EP_MUNIT"      = "Percentage of housing in structures with 10 or more units",
  "MP_MUNIT"      = "Percentage of housing in structures with 10 or more units MOE",
  "EP_MOBILE"     = "Percentage of mobile homes",
  "MP_MOBILE"     = "Percentage of mobile homes MOE",
  "EP_CROWD"      = "Percentage of occupied housing units with more people than rooms",
  "MP_CROWD"      = "Percentage of occupied housing units with more people than rooms MOE",
  "EP_NOVEH"      = "Percentage of households with no vehicle available",
  "MP_NOVEH"      = "Percentage of households with no vehicle available MOE",
  "EP_GROUPQ"     = "Percentage of persons in group quarters",
  "MP_GROUPQ"     = "Percentage of persons in group quarters MOE",
  "E_GRAPI"       = "Housing units with GRAPI ≥ 35% estimate",
  "M_GRAPI"       = "Housing units with GRAPI ≥ 35% estimate MOE",
  "EP_GRAPI"      = "Percentage of housing units with GRAPI ≥ 35%",
  "MP_GRAPI"      = "Percentage of housing units with GRAPI ≥ 35% MOE",
  "E_SNAP"        = "Households receiving SNAP benefits estimate",
  "M_SNAP"        = "Households receiving SNAP benefits estimate MOE",
  "EP_SNAP"       = "Percentage of households receiving SNAP benefits",
  "MP_SNAP"       = "Percentage of households receiving SNAP benefits MOE",
  "EP_NO_SMARTPH" = "Percentage of households without a Smartphone computing device",
  "MP_NO_SMARTPH" = "Percentage of households without a Smartphone computing device MOE",
  "E_DENSITY"     = "Number of people per square mile",
)

st_write(svi_results, './SVI_variables_2020_2024.geojson', driver = "GeoJSON", delete_layer = TRUE)
