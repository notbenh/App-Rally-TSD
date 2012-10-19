HMC = (date) -> moment(date).format('HH:mm.cc')
UTC_HMC = (date) -> moment(date).utc().format('HH:mm.cc')

TIME = (time) ->
  # TODO this will crap out over midnight as date's change
  [junk,op,time] = time.toString().match(/^([+-])?(.*)/)

  if time.match(/:/) and time.match(/[.]/)
    [junk,H,M,C] = time.toString().match(/(\d*):(\d*)[.](\d*)/)
  else if time.match(/:/)
    [junk,H,M,S] = time.toString().match(/(\d*):(\d*):?(\d*)/)
  else if time.match(/[.]{2}/)
    [junk,Ms] = time.toString().match(/(\d*)[.]{2}(\d*)/)
  else if time.match(/[.]/)
    [junk,M,C] = time.toString().match(/(\d*)[.](\d*)/)
  else
    C = time

  M = moment.duration({ hours:        parseInt(H ? 0)
                      , minutes:      parseInt(M ? 0)
                      , seconds:      parseInt((C ? 0) * 60/100) ? S 
                      , milliseconds: parseInt(Ms ? 0)
                      })
  return M.valueOf()

class EventLog
  constructor: (@id) ->
    @log = []
    @odo_factor = 1
    @time_hack = 0

  setTimeOffset: (time) ->
    @time_hack = moment(time,'HH:mm') - (new Date)

  add: (event) ->
    if typeof event == 'string'
      event = new TimeEvent(event) # assume that we passed a note
    else if event instanceof TimeEvent
      # do nothing as we have been passed a proper object
    else
      event = new TimeEvent('automated')
   
    event.time = event.date - @first().date if @first()?
    event.diff = event.date - @last().date if @last()?
    event.cast = @last()?.cast
    event.calculate()

    #@log.push( event ) # I'm going to reverse the stack 
    @log.unshift( event )

  getId: (id) -> if id == -1 then return @first else @log[id]
  last: -> @log[0]
  first: -> @log[ @log.length - 1]
  disp_lap_diff: (event,id) ->  # TODO THIS IS SUCH A HACK !!!
    fact_dist   = event.dist * @odo_factor
    prev        = @getId(id + 1) # !!! remember that this is a reversed stack
    dist_diff   = (fact_dist - prev?.dist) ? 0
    should_have = ((dist_diff * 60) / event.cast) * (1000 * 60) # miliseconds
    the_diff = event.diff - should_have
    the_time = UTC_HMC(new Date(Math.abs(the_diff)))
    #console.info(""" #{fact_dist} - #{prev?.dist} = #{dist_diff} => #{should_have} thus #{the_diff} => #{the_time} """)
    if the_diff > 0      then return "SLOW&nbsp;#{the_time}"
    else if the_diff < 0 then return "FAST&nbsp;#{the_time}"
    else ''

  # TODO this is a mess, I should not really be building a table here (isn't there a template for this?)
  display: ->
    table = """
            <table>
              <tr>
                <th>id</th>
                <th>tod</th>
                <th>split</th>
                <th>lap</th>
                <th>&Delta;lap</th>
                <th>CAST</th>
                <!--
                <th>CAST<sub>actual</sub></th>
                <th>CAST<sub>calculated</sub></th>
                <th>&Delta;CAST</th>
                --!>
                <th>dist<sub>miles</sub></th>
                <th>note</th>
              </tr>
            """
    table += """
               <tr class='#{'important' if event.important}'>
                 <th>#{id}</th>
                 <td>#{HMC(event.date) }</td>
                 <td>#{UTC_HMC( new Date(event.time)) }</td>
                 <td>#{UTC_HMC( new Date(event.diff)) }</td>
                 <td>#{@disp_lap_diff(event,id)}</td>
                 <td>#{event.cast}</td>
                 <!--
                 <td>#{parseFloat(event._cast).toFixed(3)}</td>
                 <td>#{parseFloat(event._cast - event.cast).toFixed(3)}</td>
                 --!>
                 <td>#{event.dist}</td>
                 <td>#{event.note}</td>
               </tr>
             """ for event,id in @log
    $(@id).html(table + '</table>')


class TimeEvent
  constructor: (@note) ->
    @date = new Date
    @time = 0 # this is set in add, it's the number of milliseconds covered since start (ie split time)
    @diff = 0 # this is the milliseconds since the last instruction (ie lap time)
    @cast = 1 #TODO this should be some kinda default?
    #@_cast= 1 # what rate should I have covered this dist/time?
    #@dist = 0 # what's the odo reading at the time of this event?
    #@_dist= 0 # what's the distance covered since the last instruction (TODO Better name? )
    @important = 0
  
  diff_in_min: ->
    @diff / (1000*60)

  diff_in_hr: ->
    @diff/(1000*60*60)

  cast_in_sec: ->
    @cast/(60*60)

  # TODO SLOPPY passing the odo factor here
  calculate: (odo_factor) ->
    # CAST = dist / diff
    @_cast = (@dist * odo_factor) / @diff_in_hr() 
    
class HeartBeat
  constructor: (@id,@interval,@action) ->
    @_ival = @setUpdateInterval()
    
  update: -> $(@id).html( @action() )
  clear:  -> clearInterval(@_ival)

  setUpdateInterval: ->
    return setInterval( @update.bind(this), @interval)

class Timer
  # TODO this should be converted to be a HeartBeat
  constructor: (@for, @beep, @close) ->
    @for   = moment().add( TIME( @for ? 0 ) ) unless typeof @for == 'Date'
    @beep  = @beep  ? 1
    @close = @close ? 1
    @_ival = @setUpdateInterval()
    
  update: ->
    now  = @for - (new Date)
    show = UTC_HMC(new Date(Math.abs(now)))
    $('#timer').html( show )
    if now <= 0 and @close then @clear()

  clear:  -> 
    clearInterval(@_ival)
    $('#timer').html('')

  setUpdateInterval: ->
    return setInterval( @update.bind(this), 10 )
    

class CLI
  # TODO I would rather have this become a hash->switch thing
  constructor: (@selector, @events) ->
    $( @selector ).keypress (event) =>
      current_value = $(@selector).val()

      if @events.keys[event.which]
        if typeof  @events.keys[event.which] == 'function'
          @events.keys[event.which]( event )
        else
          console.info('THIS HAS NOT YET BEEN IMPLEMENTED')
      else if current_value in @events.values?
        if typeof @events.values[ current_value ] == 'function'
          @events.values[ current_value ]( event )
          msg = "key match for #{current_value}"
          console.info(msg)
        else
          console.info('THIS HAS NOT YET BEEN IMPLEMENTED')
      else if @events.default
        # @events.default( event )
      else
        # console.info( 'ultra default' )

    $( @selector ).focus()

  me: ->
    return $(@selector)

  val: ->
    return $(@selector).val()

  clear: ->
    $(@selector).val('')

## --------------------------------------------------------------------------- ##

$ ->
  e = new EventLog('#log')
  buffer = new CLI( '#buffer' ,
                    keys  :
                      32: ->
                        e.add()
                        e.display()
                        buffer.clear()
                      13: ->
                        # TODO this should not directly access 
                        [junk,id,method,value] = $('#buffer').val().match(/^\s*(\d*)([a-z!]*):?(.*)/)
                        console.info(['ENTER HIT',id,method,value])
                        id = 0 unless id.length
                        switch method
                          when 'rm'     then e.log.splice(id,1)
                          when 'reset'
                            e.log = []
                            $('#expected_distance').html('')
                          when 'update' then e.display()
                          when 'odo'    then e.odo_factor = value / e.last().dist
                          when 'time'   then e.setTimeOffset(value)
                          when 'p'
                            e.timer?.clear()
                            e.timer = new Timer(value,1,1)
                          when 'cd'
                            e.timer?.clear()
                            e.timer = new Timer(value,1,0)
                          when 'clear'
                            e.timer?.clear()
                          when '!' 
                            it = e.getId(id)
                            it.important = not it.important
                            console.info(it)
                          when '' # TODO this could be a bit dangrous
                            string_value = (id + value).toString()
                            if string_value.match /[@]/
                              [dist,cast] = string_value.split('@') 
                            else
                              dist = parseInt(id) + parseFloat(value)
                              cast = undefined
                            #console.info(" DIST #{dist} CAST #{cast} from '#{string_value}'")
                            it = e.last()
                            it.dist = dist if dist
                            it.cast = cast if cast
                            it.calculate(e.odo_factor)
                          else
                            it = e.getId(id)
                            if typeof it[method] is 'function' then it[method](value) else it[method] = value
                            it.calculate(e.odo_factor)
                        e.display()
                        buffer.clear()
                    default : ->
                  )
  odofactor     = new HeartBeat( '#odo'              , 1000, -> e.odo_factor )
  timehack      = new HeartBeat( '#time'             , 1000, -> e.time_hack )
  clock_tod     = new HeartBeat( '#tod'              , 100 , -> HMC(new Date((new Date).valueOf() + e.time_hack) ))
  current_cast  = new HeartBeat( '#current_cast'     , 1000, -> e.last()?.cast )
  expected_dist = new HeartBeat( '#expected_distance', 1000, ->
                                                               now     = new Date
                                                               since   = now - e.last()?.date # mseconds
                                                               covered = ( e.last()?.cast * (since / (1000*60*60)) ) / e.odo_factor
                                                               (parseFloat(e.last()?.dist ) + covered).toFixed(2)
                               )
