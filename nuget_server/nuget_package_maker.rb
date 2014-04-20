=begin
	The scripts reads a JSON file (nuget_package_settings.json) which contains the specifications
	for and is able to regenerate all your specified packages. The generated packages can be moved
	to a server folder (the nuget server packages folder).
=end

require 'fileutils'
require 'json'

def regenerate_nuspec(text, settings)
  text = text.sub(/<id>.*<\/id>/, "<id>"+settings["projectName"]+"</id>")
  text = text.sub(/<version>.*<\/version>/, "<version>"+settings["version"]+"</version>")
  text = text.sub(/<title>.*<\/title>/, "<title>"+settings["title"]+"</title>")
  text = text.sub(/<authors>.*<\/authors>/, "<authors>"+settings["author"]+"</authors>")
  text = text.sub(/<owners>.*<\/owners>/, "<owners>"+settings["author"]+"</owners>")
  text = text.sub(/<licenseUrl>.*<\/licenseUrl>/, "<licenseUrl>"+settings["licenseUrl"]+"</licenseUrl>")
  text = text.sub(/<projectUrl>.*<\/projectUrl>/, "<projectUrl>"+settings["projectUrl"]+"</projectUrl>")
  text = text.sub(/<iconUrl>.*<\/iconUrl>/, "<iconUrl>"+settings["iconUrl"]+"</iconUrl>")
  text = text.sub(/<description>.*<\/description>/, "<description>"+settings["description"]+"</description>")
  text = text.sub(/<releaseNotes>.*<\/releaseNotes>/, "<releaseNotes>"+settings["releaseNotes"]+"</releaseNotes>")
  text = text.sub(/<copyright>.*<\/copyright>/, "<copyright>"+settings["copyright"]+"</copyright>")
  text = text.sub(/<tags>.*<\/tags>/, "<tags>"+settings["tags"]+"</tags>")
  text = text.sub(/<\/package>/, "")
  text = text.sub(/<\/metadata>/, "")

  text += "\t\t<dependencies>\n"
  settings["dependencies"].each{ |dependency| text += "\t\t\t<dependency id=\"" + dependency["id"] +"\" version=\"" +dependency["version"] +"\"/>\n" }
  text += "\t\t</dependencies>\n"
  text += "\t</metadata>\n"
  
  text += "\t<files>\n"
  settings["files"].each{ |file| text += "\t\t<file src=\"" + file["source"] +"\" target=\"" +file["destination"] +"\"/>\n" }
  text += "\t</files>\n"
  text += "</package>"
  
  return text
end

def create_specification(project_name, settings)
  package_path = settings["path"]
  project_name = settings["projectName"]
  nuspec_file = project_name + ".nuspec"

  Dir.chdir(package_path) 
  nuspec_file = project_name + ".nuspec"
  
  system("nuget spec -f")
  
  nuspec_file_path = File.join(package_path, nuspec_file)
  nuspec_content = IO.read(nuspec_file_path)
  nuspec_content = regenerate_nuspec(nuspec_content, settings)
  IO.write(nuspec_file_path, nuspec_content)
  
  return nuspec_file_path;
end

def process_package(settings, packages_folder) 
  project_name = settings["projectName"] 
  nuspec_file_path = create_specification(project_name, settings)  
  
  pack_command = "nuget pack " + nuspec_file_path + " -OutputDirectory " + packages_folder
  system(pack_command) 
  
  nupkg_file = project_name + settings["version"] + ".nupkg"
  nupkg_file_path = File.join(packages_folder, nupkg_file)
  
  upload_to_server(nupkg_file_path) 
end

def upload_to_server(filename)
  #TBD
end

configContent = IO.read("nuget_package_settings.json")
config = JSON.parse(configContent)
config["packages"].each{ |package| process_package(package, config["packageFolder"])}
