# Import librariesimport osimport pandas as pdimport glob# set work directorywork_dir="/Users/davidlord/Documents/External_data/script_running/BioLung_data/"os.chdir(work_dir)# Read data filenewFile = pd.ExcelFile('BioLung_variants_manually_classified.xlsx')ParsedData = pd.io.parsers.ExcelFile.parse(newFile)