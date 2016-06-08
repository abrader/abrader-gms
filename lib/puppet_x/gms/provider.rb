# Forward declaration(s)
module PuppetX; end
module PuppetX::GMS; end

module PuppetX::GMS::Provider
  def get_token
    @token ||= if resource[:token]
      resource[:token].strip
    elsif resource[:token_file]
      File.read(resource[:token_file]).strip
    else
      raise(Puppet::Error, "github_webhook::#{calling_method}: Must provide at least one of the following attributes: token or token_file")
    end
  end
end
