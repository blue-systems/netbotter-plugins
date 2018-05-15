# Meeting Plugin
class MeetingPlugin < Plugin
  def initialize(*args)
    super
    reset!
  end

  def help(_, _)
    <<-HELP
roll call => highlight everyone and the kitchen sink, records anyone saying anything as present
next => move to next person in queue
move :name up => moves the nick :name to the front of the queue
take chair => take the chair for yourself. gives you `next` powers. there may only be one!
give chair to :name => give the chair to someone else
    HELP
  end

  def unreplied(m, **_)
    return unless @active
    source = m.sourcenick
    return if @pending.include?(source) || @done.include?(source)
    @pending.insert(-2, source) # Chair is always, last, insert before.
  end

  def roll_call(m, **_)
    @chair = m.sourcenick
    @pending = [@chair] # Chair is first in array, but last overall.
    nicks = m.channel.users.collect(&:nick)
    nicks.reject! { |n| n == bot.nick }
    m.reply "Roll Call! #{nicks.join(', ')}"
    @active = true
  end

  def take_chair(m, name: nil, **_)
    return if abort_active?(m)
    @chair = name || m.sourcenick
    m.reply "The Right Honourable #{@chair} is now presiding."
  end

  def next(m, **_)
    return if abort_active?(m)
    return if abort_chair?(m)
    @current = @pending.shift
    m.reply "Next up #{@current} (followed by #{@pending.fetch(0, 'silence!')})"
    @done << @current

    reset! if @pending.empty?
  end

  def debug(_, **_)
    p @pending
    p @done
    p @active
    p @current
    p ['chair', @chair]
  end

  def done(_, **_)
    reset!
  end

  def move_up(m, name:, **_)
    return if abort_active?(m)
    nick = @pending.delete(name)
    unless nick
      m.reply "#{name} not in pending stack"
      return
    end
    @pending.unshift(nick)
    m.reply "Moved #{nick} to the front of the queue."
  end

  def move_back(m, name:, **_)
    return if abort_active?(m)
    return if @pending.empty?
    nick = @pending.delete(name)
    @pending.insert(-2, name)
    m.reply "Moved #{nick} to the back of the queue."
  end

  private

  def abort_chair?(m)
    unless m.sourcenick == @chair
      m.reply "To avoid confusion, only the chair (#{@chair}) may progress." \
              ' Or you may take the chair with `take chair`.'
      return true
    end
    false
  end

  def abort_active?(m)
    unless @active
      m.reply 'No meeting in progress. Either do a roll call, or we are done!'
      return true
    end
    false
  end

  def reset!
    @pending = []
    @done = []
    @active = false
    @current = nil
    @chair = nil
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
plugin.map 'rollcall', action: 'roll_call'
plugin.map 'rolecall', action: 'roll_call'
plugin.map 'debug', action: 'debug'
plugin.map 'meeting done', action: 'done'
plugin.map 'next', action: 'next'
plugin.map 'done', action: 'next'
plugin.map 'meeting next', action: 'next'
plugin.map 'start', action: 'next'
plugin.map 'meeting start', action: 'next'
plugin.map 'move :name up', action: 'move_up'
# plugin.map 'move :name back', action: 'move_back'
plugin.map 'take chair', action: 'take_chair'
plugin.map 'give chair to :name', action: 'take_chair'
