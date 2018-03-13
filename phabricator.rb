# encoding: utf-8
# frozen_string_literal: true
#
# Copyright (C) 2016 Harald Sitter <sitter@kde.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of
# the License or any later version accepted by the membership of
# KDE e.V. (or its successor approved by the membership of KDE
# e.V.), which shall act as a proxy defined in Section 14 of
# version 3 of the license.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require(File.expand_path('lib/differential', File.dirname(__FILE__)))
require(File.expand_path('lib/maniphest', File.dirname(__FILE__)))
require(File.expand_path('lib/project', File.dirname(__FILE__)))

# Phabricator Plugin
class PhabricatorPlugin < Plugin
  Config.register Config::StringValue.new('phabricator.api_token',
                                          :requires_rescan => true,
                                          :default => '',
                                          :desc => 'Phabricator API token to use for conduit.')

  def initialize
    super
    Conduit::Connection.api_token = bot.config['phabricator.api_token']
  end

  def unreplied(m, _ = {})
    return if skip?(m)
    maybe_task(m) unless m.replied?
    maybe_diff(m) unless m.replied?
  end

  def maybe_task(m)
    return unless (match = m.message.scan(/\bT(\d+)\b+/))
    match.flatten.each do |number|
      task(m, number: number)
    end
  end

  def maybe_diff(m)
    return unless (match = m.message.scan(/\bD(\d+)\b/))
    match.flatten.each do |number|
      diff(m, number: number)
    end
  end

  def task(m, options = {})
    number = options.fetch(:number)
    task = Conduit::Maniphest.get(number)
    projects = Conduit::Project.find_by_phids(task.projectPHIDs)
    m.reply "Task #{task.id} \"#{task.title}\" [#{task.statusName},#{task.priority}] {#{projects.collect(&:name).join(',')}} #{task.uri}"
  rescue => e
    m.notify "Task not found ¯\\_(ツ)_/¯ #{e}"
  end

  def diff(m, options = {})
    number = options.fetch(:number)
    diff = Conduit::Differential.get(number)
    m.reply "Diff #{diff.id} \"#{diff.title}\" [#{diff.statusName}] #{diff.uri}"
  rescue => e
    m.notify "Diff not found ¯\\_(ツ)_/¯ #{e}"
  end

  private

  def skip?(m)
    %w(#kde-bugs-activity).any? do |exclude|
      m.channel && m.channel.name == exclude
    end
  end
end

PhabricatorPlugin.new unless ENV['DONT_TEST_INIT']
