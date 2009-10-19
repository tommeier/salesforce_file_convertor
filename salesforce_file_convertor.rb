require 'rubygems'
require 'fastercsv'
  
#Loop through csvs in root of script
Dir.foreach(".") do |item|
  extension = File.extname(item)
  if extension.downcase == ".csv"
     file_name = File.basename(item, extension)
     dir_name = file_name.downcase[-1,1] == 's' ? file_name : "#{file_name}s"
     if File.exist?(dir_name) && File.directory?(dir_name)
       parsed_file = FasterCSV.parse(File.open(item,'r'),{:headers => true, :return_headers => false, :skip_blanks => true})
       next unless parsed_file
       item_mapping = {}
       parsed_file.each  do |row| 
          item_id    = row[parsed_file.headers.index("Id")].to_s.strip
          item_name  = row[parsed_file.headers.index("Name")].to_s.strip                       
          item_ext   = row[parsed_file.headers.index("ContentType")].to_s.strip
          next if item_id.nil? || item_name.nil?
          item_mapping.update(item_id => {:name => item_name, :extension => item_ext})
       end
       puts " -- Processing #{item}" 
       processed_dir = FileUtils.mkdir_p(File.join("Processed", dir_name))
       item_mapping.each do |k, v|
          source      = File.join(dir_name, k)
          file_ext    = File.extname(v[:name]).strip
          if file_ext.nil? || file_ext == ""
            extension = case v[:extension].to_s.strip.downcase
                               when "message/rfc822"; ".mht"
                               when "application/msword"; ".doc"
                               when "image/jpeg"; ".jpg"
                               when "image/gif"; ".gif"
                               when "application/pdf"; ".pdf"
                               when "text/plain"; ".txt" 
                               else 
                                 lines = IO.readlines(source)
                                 /Subject:||/.match(lines.first) && lines.size == 1 ? ".eml" : ".html"
                               end
            output_file_name = "#{v[:name]}#{extension}"
          else
            output_file_name = v[:name]
          end 
          FileUtils.copy source, File.join(processed_dir, output_file_name) if File.exist?(File.join(dir_name, k))
          puts "Created #{output_file_name}."
       end  
     end
  end
end

