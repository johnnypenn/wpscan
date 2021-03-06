#
# WPScan - WordPress Security Scanner
# Copyright (C) 2011  Ryan Dewhurst AKA ethicalhack3r
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class WpTarget
  include WebSite
  include WpReadme
  include WpFullPathDisclosure
  include WpConfigBackup
  include WpLoginProtection
  include Malwares
  include WpUsernames
  include WpTimthumbs
  include WpPlugins
  include BruteForce

  @error_404_hash = nil

  attr_reader :uri, :verbose

  def initialize(target_url, options = {})
    raise "Empty URL" if !target_url

    @uri            = URI.parse(add_http_protocol(target_url))
    @verbose        = options[:verbose]
    @wp_content_dir = options[:wp_content_dir]
    @wp_plugins_dir = options[:wp_plugins_dir]

    Browser.instance(#options.merge(:max_threads => options[:threads]))
      :proxy       => options[:proxy],
      :max_threads => options[:threads]
    )
  end

  # Alias of @uri.to_s
  def url
    @uri.to_s
  end

  def login_url
    url = @uri.merge("wp-login.php").to_s

    # Let's check if the login url is redirected (to https url for example)
    if redirection = redirection(url)
      url = redirection
    end

    url
  end

  # Return the MD5 hash of a 404 page
  def error_404_hash
    unless @error_404_hash
      non_existant_page = Digest::MD5.hexdigest(rand(9999999999).to_s) + ".html"

      response = Browser.instance.get(@uri.merge(non_existant_page).to_s)

      @error_404_hash = Digest::MD5.hexdigest(response.body)
    end

    @error_404_hash
  end

  # return WpTheme
  def theme
    WpTheme.find(@uri)
  end

  # return WpVersion
  def version
    WpVersion.find(@uri)
  end

  def wp_content_dir
    unless @wp_content_dir
      index_body = Browser.instance.get(@uri.to_s).body

      if index_body[%r{/wp-content/themes/}i]
        @wp_content_dir = "wp-content"
      else
        @wp_content_dir = index_body[%r{(?:href|src)=(?:"|')#{@uri}/?(.*)/themes/.*(?:"|')}i, 1]
      end
    end
    @wp_content_dir
  end

  def wp_plugins_dir
    unless @wp_plugins_dir
      @wp_plugins_dir = wp_content_dir() + "/plugins"
    end
    @wp_plugins_dir
  end

  def has_debug_log?
    Browser.instance.get(debug_log_url()).body[%r{\[[^\]]+\] PHP (?:Warning|Error):}] ? true : false
  end

  def debug_log_url
    @uri.merge("#{wp_content_dir()}/debug.log").to_s
  end

end
