#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'services/base_services/behaves_like_create_service'

describe Notifications::CreateService, type: :model do
  it_behaves_like 'BaseServices create service' do
    let(:call_attributes) do
      {}
    end

    context 'when successful' do
      before do
        allow(set_attributes_service)
          .to receive(:call) do |attributes|
          model_instance.attributes = attributes

          set_attributes_result
        end
      end

      context 'when mail ought to be send', { with_settings: { notification_email_delay_minutes: 30 } } do
        let(:call_attributes) do
          {
            read_email: false
          }
        end

        it 'schedules a delayed event notification job' do
          allow(Time)
            .to receive(:now)
                  .and_return(Time.now)

          expect { subject }
            .to have_enqueued_job(Mails::NotificationJob)
                 .with({ "_aj_globalid" => "gid://open-project/Notification/#{model_instance.id}" })
                 .at(Time.now + Setting.notification_email_delay_minutes.minutes)
        end
      end

      context 'when mail not ought to be send' do
        let(:call_attributes) do
          {
            read_email: nil
          }
        end

        it 'schedules no event notification job' do
          expect { subject }
            .not_to have_enqueued_job(Mails::NotificationJob)
        end
      end
    end

    context 'when unsuccessful' do
      let(:model_save_result) { false }

      it 'schedules no job' do
        expect { subject }
          .not_to have_enqueued_job(Mails::NotificationJob)
      end
    end
  end
end