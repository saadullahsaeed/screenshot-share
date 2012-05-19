#!/usr/bin/env ruby -KU

require 'rubygems'
require 'fssm'
require 'crack/json'
require 'curb'
require 'ruby-growl'
require 'yaml'
require 'oauth'

def log(text)
  
  #puts "#{text}"
end


def copy_to_clipboard(text)
  
  IO.popen('pbcopy', 'r+') { |clipboard| clipboard.puts text }
end


def notify_growl(file, url)
  
  system "growl -H 127.0.0.1 -t \"Screenshot Uploaded\" -m \"File: #{file} has been uploaded to: #{url}\" --sticky"
end


def notify_growl_of_error
  
  system "growl -H 127.0.0.1 -t \"Error Uploading Screenshot\" -m \"Bummer :( Try again, maybe?\" --sticky"
end



def upload_anonymous(file_path)
  puts "Uploading anonymous"
  begin
      
      c = Curl::Easy.new("http://imgur.com/api/upload.json")
      c.multipart_form_post = true

      c.http_post(Curl::PostField.content('key', $config['key']), Curl::PostField.file('image', file_path))
      response = Crack::JSON.parse c.body_str
      image_url = response["rsp"]["image"]["original_image"]
      
   rescue Exception => exception

     log exception.message
   end

   image_url
end



def upload_using_oauth(file_path)
  
  begin

    request_params = {
      :key => $config['key'],
      :image => Base64.encode64(File.read file_path),
      :type => 'base64'
    }
    
    response = $consumer.request(:post, '/account/images.json', $access_token, {}, request_params)
    result = Crack::JSON.parse response.body

    image_url = result["images"]["links"]["original"]
    
  rescue Exception => exception
    
    log exception.message
  end
  
  image_url
end



def upload_to_imgur(base, file)
  
  file_path = "#{base}/#{file}"
  
  if $config['anonymous']
    image_url = upload_anonymous file_path
  else
    image_url = upload_using_oauth file_path  
  end
  
  if not image_url
    notify_growl_of_error
    return
  end
  
  copy_to_clipboard image_url
  notify_growl file, image_url
  
end


config_file = ARGV[0]
if not config_file then abort "Usage: main.rb /path/to/config.yaml" end

$config = YAML.load(File.read(config_file))

#
if not $config['anonymous']
  $consumer = OAuth::Consumer.new($config['consumer_key'], $config['consumer_secret'], {:site=>"https://api.imgur.com/2"})
  $access_token = OAuth::AccessToken.from_hash($consumer, {:oauth_token=>$config['oauth_token'], :oauth_token_secret => $config['oauth_token_secret']})
end

FSSM.monitor($config['listen_to_dir'], ['**/*.png']) do
  create { |base, relative, type| upload_to_imgur base, relative }
end

exit 0
