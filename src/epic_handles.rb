=begin License
  Copyright ©2011-2012 Pieter van Beek <pieterb@sara.nl>
  
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  
      http://www.apache.org/licenses/LICENSE-2.0
  
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
=end

require 'epic_collection.rb'
require 'epic_sequel.rb'

module EPIC

class Handles < Collection

  def prefix
    @epic_handles_prefix ||= File::basename(path.unslashify).to_path.unescape
  end

=begin rdoc
TODO: better implementation (server-side data retention) for streaming responses.
=end
  def each
    start_position = self.prefix.size + 1
    DB.instance.each_handle do
      |handle|
      yield Rackful::Path.new( self.path + escape_path(handle[start_position .. -1]) )
    end
    # end
  end

  add_media_type 'application/json', :POST
  add_media_type 'application/x-json', :POST

  # Handles an HTTP/1.1 PUT request.
  # @see Rackful::Resource#do_METHOD
  def do_POST request, response
    generator_name = request.GET['generator'] || EPIC::DEFAULT_GENERATOR
    unless generator = request.resource_factory["/generators/#{generator_name}"]
      raise Rackful::HTTP400BadRequest, "No such generator: '#{generator_name}'"
    end
    pid_suffix = generator.generate( request )
    handle = request.resource_factory["/handles/#{prefix}/#{pid_suffix}"]
    begin
      handle.do_PUT( request, response )
    ensure
      #~ Maybe the response needs to be altered, because the semantics of a 
      #~ PUT request differ from those of a POST request.
    end
  end

end # class Handles

end # module EPIC
