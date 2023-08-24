require 'spec_helper'
require 'grocer'

describe Passbook::PushNotification  do

  context 'send notification' do
    let(:grocer_pusher) {double 'Grocer'}
    let(:notification) {double 'Grocer::Notification'}
    let(:notification_settings) {{:certificate => './notification_cert.pem', :gateway => 'honeybadger.apple.com', :passphrase => 'ah@rdvintAge'}}

    before :each do
      allow(Passbook).to(receive(:notification_cert).and_return('./notification_cert.pem'))
      allow(Grocer::PassbookNotification).to(receive(:new).with(:device_token => 'my token').and_return(notification))
      allow(grocer_pusher).to(receive(:push).with(notification).and_return(55))
      allow(Grocer).to(receive(:pusher).with(notification_settings).and_return(grocer_pusher))
      allow(Passbook).to(receive(:notification_gateway).and_return('honeybadger.apple.com'))
      allow(Passbook).to(receive(:notification_passphrase).and_return('ah@rdvintAge'))
    end

    subject {Passbook::PushNotification.send_notification('my token')}
    it {should eq 55}
  end
end
