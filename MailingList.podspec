
Pod::Spec.new do |s|
  s.name             = 'MailingList'
  s.version          = '0.1.0'
  s.summary          = 'Prompts for users to sign up to your mailing list, using the MailGun API'

  s.description      = <<-DESC
  Prompts for users to sign up to your mailing list, using the MailGun API.
                       DESC

  s.homepage         = 'https://github.com/megatron1000/MailingList'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'megatron1000' => 'mark@bridgetech.io' }
  s.source           = { :git => 'https://github.com/megatron1000/MailingList.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/markbridgesapps'

  s.platform     = :osx, '10.11'

  s.source_files = 'MailingList/Classes/**/*'

  s.resource_bundles = {
    'MailingList' => ['MailingList/Assets/**/*']
  }

end
