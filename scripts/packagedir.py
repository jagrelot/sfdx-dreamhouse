#Copyright © 2018 Acumen Solutions, Inc. The Thorax Salesforce Metadata Utility was
#created by Acumen Solutions. Except for the limited rights to use and make copies
#of the Software as provided in a License Agreement, all rights are reserved.

import sys, getopt, os, shutil, constants

FOLDER_TO_METADATA = constants.FOLDER_TO_METADATA
OLD_SHARED_FOLDERS = constants.OLD_SHARED_FOLDERS
NEW_SHARED_FOLDERS = constants.NEW_SHARED_FOLDERS
TEMP_FOLDERS = constants.TEMP_FOLDERS
PACKAGE_FILES = constants.PACKAGE_FILES
FOLDER_COMPONENTS = constants.FOLDER_COMPONENTS

def getOptions(argv):
	try:
		opts, args = getopt.getopt(argv, 'i:v:')
	except getopt.GetoptError:
		print('createPackage.py -i <srcDirectory> -v <apiVersion>')
		sys.exit();

	return opts

def getFiles(parent, document = False):
	allFiles = []
	for file in os.listdir(parent):
		if '-meta.xml' in file:
			continue
		if file != 'unfiled$public':
			if document:
				allFiles.append(file)
			else:
				allFiles.append(file.rsplit('.', 1)[0])
		newPath = os.path.join(parent,file)
		if (os.path.isdir(newPath)) and parent not in FOLDER_COMPONENTS:
			if parent == 'documents':
				document=True
			for child in getFiles(newPath, document):
				allFiles.append(file + '/' + child)
	return allFiles

def getMap(srcDir):
	dirXmlStarMap = []
	for parent in os.listdir(srcDir):
		if parent in PACKAGE_FILES:
			continue
		try:
			xmlNameArray = FOLDER_TO_METADATA[parent]
			xmlName = xmlNameArray[0]
			starNotated = xmlNameArray[1]
			dirXmlStarMap.append([parent, xmlName, starNotated])
		except:
			print(parent, ' is not a recognized metadata folder')
			continue
	dirXmlStarMap.sort(key=lambda x: x[1])
	return dirXmlStarMap

def copyToTempFolders(directoryToParse):
	for row in NEW_SHARED_FOLDERS:
		baseFolder = row[0]
		extension = row[1]
		if baseFolder in os.listdir(directoryToParse):
			for file in os.listdir(baseFolder):
				if file.endswith(extension):
					oldFile = directoryToParse + '/' + baseFolder + '/' + file
					newFile = directoryToParse + '/' + extension + '/' + file
					if not os.path.exists(extension):
						os.mkdir(extension)
					shutil.copy(oldFile, newFile)

def copyTerritory2Rules(directoryToParse):
	territory2Models = directoryToParse + '/territory2Models'
	territory2Rules = directoryToParse + '/territory2Rule/'
	
	if os.path.exists(territory2Models):
		if not os.path.exists('territory2Rule'):
			os.mkdir('territory2Rule')
		for model in os.listdir(territory2Models):
			modelFolder = territory2Models + '/' + model
			for subModel in os.listdir(modelFolder):
				rulesFolder = modelFolder + '/rules'
				for file in os.listdir(rulesFolder):
					if file.endswith('.territory2Rule'):
						oldFile = rulesFolder + '/' + file
						newFile = territory2Rules + file
						shutil.copy(oldFile, newFile)

def separateSharedFolders(directoryToParse):
	copyToTempFolders(directoryToParse)
	copyTerritory2Rules(directoryToParse)

def deleteTemp():
		for folder in TEMP_FOLDERS:
			if os.path.exists(folder):
				shutil.rmtree(folder)

def printOutput(srcDir, version):
	with open('package.xml', 'w+') as f:
		f.seek(0)
		f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
		f.write('<Package xmlns="http://soap.sforce.com/2006/04/metadata">\n')
		directoryXmlStarMap = getMap(srcDir)
		for row in directoryXmlStarMap:
			folder = row[0]
			xmlName = row[1]
			star = row[2]
			if  folder in OLD_SHARED_FOLDERS:
				continue
			f.write('    <types>\n')
			if star:
				f.write('        <members>*</members>\n')
			else:
				for fileName in sorted(getFiles(folder)):
					f.write('        <members>' + fileName + '</members>\n')
			f.write('        <name>' + xmlName + '</name>\n')
			f.write('    </types>\n')
		f.write('    <version>' + '{:03.1f}'.format(version) + '</version>\n')
		f.write('</Package>')
		f.truncate()

def main(argv):
	directoryToParse = ''
	version = 0.0

	opts = getOptions(argv)

	for opt, arg in opts:
		if opt == '-i':
			directoryToParse = arg
		elif opt == '-v':
			version = float(arg)

	if directoryToParse == '':
		directoryToParse = os.path.dirname(os.path.realpath(__file__))

	os.chdir(directoryToParse)
	separateSharedFolders(directoryToParse)
	printOutput(directoryToParse, version)
	deleteTemp()
	print('package.xml created successfully!')

if __name__ == "__main__":
	main(sys.argv[1:])

