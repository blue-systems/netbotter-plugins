# Meeting Plugin
class MeetingPlugin < Plugin
  def initialize(*args)
    super
    reset!
  end

  def help(_, _)
    ':meeting roll call => highlight everyone and the kitchen sink'
  end

  def unreplied(m, **_)
    return unless @active
    source = m.sourcenick
    return if @pending.include?(source) || @done.include?(source)
    @pending.insert(-2, source) # Chair is always, last, insert before.
  end

  def roll_call(m, **_)
    nicks = m.channel.users.collect(&:nick)
    nicks.reject! { |n| n == bot.nick }
    m.reply("Roll Call! #{nicks.join(', ')}")
    @pending = [m.sourcenick] # Chair is first in array, but last overall.
    @active = true
  end

  def next(m, **_)
    unless @active
      m.reply 'No meeting in progress. Either do a roll call, or we are done!'
      return
    end
    @current = @pending.shift
    # unless @current
    #   m.reply 'Out of people to harass :( - End by telling me: meeting done'
    #   return
    # end
    m.reply "Next up #{@current} (followed by #{@pending.fetch(0, 'silence!')})"
    @done << @current

    reset! if @pending.empty?
  end

  def debug(_, **_)
    p @pending
    p @done
    p @active
    p @current
  end

  def done(_, **_)
    reset!
  end

  def move_up(m, name:, **_)
    unless @active
      m.reply 'No meeting in progress. Do a roll call first?'
      return
    end
    nick = @pending.delete(name)
    unless nick
      m.reply "#{name} not in pending stack"
      return
    end
    @pending.unshift(nick)
    m.reply "Moved #{nick} to the front of the queue."
  end

  private

  def reset!
    @pending = []
    @done = []
    @active = false
    @current = nil
  end
end

plugin = MeetingPlugin.new
plugin.map 'meeting', action: 'roll_call'
plugin.map 'meeting roll call', action: 'roll_call'
plugin.map 'meeting role call', action: 'roll_call'
plugin.map 'meeting rolecall', action: 'roll_call'
plugin.map 'role call', action: 'roll_call'
plugin.map 'role cal', action: 'roll_call'
plugin.map 'call', action: 'roll_call'
plugin.map 'roll call', action: 'roll_call'
plugin.map 'debug', action: 'debug'
plugin.map 'meeting done', action: 'done'
plugin.map 'next', action: 'next'
plugin.map 'done', action: 'next'
plugin.map 'meeting next', action: 'next'
plugin.map 'start', action: 'next'
plugin.map 'meeting start', action: 'next'
plugin.map 'move :name up', action: 'move_up'
# plugin.map 'move :name back', action: 'move_back'
