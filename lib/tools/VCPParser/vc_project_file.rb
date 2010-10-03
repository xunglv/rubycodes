require 'rexml/document'
include REXML
require 'fileutils'

PATH_SEP = "\\"

class VCProjectFile
  def initialize(filename)
    @filename=filename
    tmp_file =  File.new(filename)
    @xmldoc = Document.new(tmp_file)

  end
  
  def export(path)
    #export source file
    XPath.each(@xmldoc, "//File") do |e|
      if !e.elements['FileConfiguration[@ExcludedFromBuild="true"]'] then
        relative_path = e.attributes["RelativePath"]
        fn_src = get_absolute_path File.dirname(@filename), relative_path
        fn_dst = get_absolute_path(path, relative_path)
        copy_file(fn_src, fn_dst)
      end
    end

    #export configurations
    fn_config = get_absolute_path(path, 'configurations.txt')
    File.open(fn_config, "w") do |outfile|
      XPath.each(@xmldoc, "//Configuration") do |e|
        outfile.puts '----configuration------'
        outfile.puts e.attributes['Name']
        e.elements.each("Tool") do |etool|
          if etool.elements["@Name='VCCLCompilerTool'"] then
            outfile.puts '--Include Folders'
            outfile.puts etool.attributes['AdditionalIncludeDirectories'];
            outfile.puts '--Preprocesser'
            outfile.puts etool.attributes['PreprocessorDefinitions'];
          end
        end
      end
    end
  end
end

def get_absolute_path(root_path, relative_path)
  path = root_path
  if path[path.length-1] != PATH_SEP then path+=PATH_SEP end
  path += relative_path
  return path
end

#create path on file system
def create_path(path)
  i=0;
  begin
    sep_pos = path.index(PATH_SEP, i);
    found_sep=true
    if !sep_pos  then  found_sep=false; sep_pos=path.length-1 end
    #
    tmp_path = path[0..sep_pos]
    if !File.exist? tmp_path then
      begin
        Dir.mkdir(tmp_path)
      end
    end
    i=sep_pos + 1
  end while found_sep
end

#
def copy_file(src, dst)
  if !File.exist?(src) then return nil end
  if File.directory?(src) then return nil end
  if !File.exist?(File.dirname dst) then create_path(File.dirname dst) end
  FileUtils.copy(src, dst, :verbose => true);
end



#test
VCP_FILENAME='d:\tmp\gnux\AS5\prj\win32\Asphalt5_VS2008.vcproj'
OUT_DIR ='D:\tmp\ap5\prj\win32'
PREPROCESS_FILE='configurations.txt'
  

puts 'processing...'

prj_file = VCProjectFile.new(VCP_FILENAME)
prj_file.export OUT_DIR

puts 'done'

#copy_file 'd:\tmp1\a.txt', 'd:\tmp\b.txt'
#d = Dir.new(".")
#d.each  {|x| puts x }
   
  