# frozen_string_literal: true
#
# Copyright (C) 2016 Harald Sitter <sitter@kde.org>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) version 3, or any
# later version accepted by the membership of KDE e.V. (or its
# successor approved by the membership of KDE e.V.), which shall
# act as a proxy defined in Section 6 of version 3 of the license.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library.  If not, see <http://www.gnu.org/licenses/>.

require(File.expand_path('connection', File.dirname(__FILE__)))
require(File.expand_path('representation', File.dirname(__FILE__)))

module Conduit
  # A project
  class Project < Representation
    class << self
      def find_by_phids(phids, connection = Connection.new)
        return [] if !phids || phids.empty?
        page = connection.call('project.query', phids: phids)
        # In the data: keys are the phids, values are the actual objects
        page[:data].values.collect do |hash|
          new(connection, hash)
        end
      end
    end
  end
end
