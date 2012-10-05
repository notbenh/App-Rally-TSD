### TODO to keep sprintf or not? currently does not do n.nf correctly 
zpad = (dig,pad) ->
  return 0 if typeof dig == 'undefned'
  pad = pad.toString() unless typeof pad == 'string'
  dig = dig.toString() unless typeof dig == 'string'

  if padS.match(/[.]/) 
    [dig1,dig2] = digS.split(/[.]/,2)
    [pad1,pad2] = padS.split(/[.]/,2)
    return zpad(dig1,pad1) + '.' + zpad(dig2.toString().substr(0,pad2),pad2)
  else
    if digS.length < pad
      digS = "0#{digS}" for x in [pad - digS.length .. 1]

    return digS
###


HMC = (date) ->
  sec = sprintf( '0.3f', date.getSeconds() * 100/60 + date.getMilliseconds() / 1000 )

  sprintf('%02d:%02d.%02.3f' \
         , date.getHours()    \
         , date.getMinutes()  \
         , date.getSeconds() * 100/60 + date.getMilliseconds() / 1000 \
         )

UTC_HMC = (date) ->
  sprintf('%02d:%02d.%02.3f' \
         , date.getUTCHours()    \
         , date.getUTCMinutes()  \
         , date.getUTCSeconds() * 100/60 + date.getUTCMilliseconds() / 1000 \
         )



class EventLog
  constructor: (@id) ->
    @log = []

  add: (event) ->
    if typeof event == 'string'
      event = new TimeEvent(event) # assume that we passed a note
    else if event instanceof TimeEvent
      # do nothing as we have been passed a proper object
    else
      event = new TimeEvent('automated')

    prev = @log[ @log.length - 1]
    #console.info(prev)

    event.time = event.date - @log[0].date if @log[0]?
    event.diff = event.date - @log[ @log.length - 1].date if @log[ @log.length - 1]?
    event.cast = prev?.cast 
    event.calculate()

    @log.push( event )

  last: -> @log[@log.length - 1]

  # TODO this is a mess, I should not really be building a table here (isn't there a template for this?)
  display: ->
    table = """
            <table>
              <tr>
                <th>id</th>
                <th>split</th>
                <th>lap</th>
                <th>CAST<sub>actual</sub></th>
                <th>CAST<sub>calculated</sub></th>
                <th>&Delta;CAST</th>
                <th>dist<sub>miles</sub></th>
                <th>note</th>
              </tr>
            """
    table += """
               <tr>
                 <th>#{id}</th>
                 <td>#{UTC_HMC( new Date(event.time)) }</td>
                 <td>#{UTC_HMC( new Date(event.diff)) }</td>
                 <td>#{event.cast}</td>
                 <td>#{event._cast}</td>
                 <td>#{event._cast - event.cast}</td>
                 <td>#{event.dist}</td>
                 <td>#{event.note}</td>
               </tr>
             """ for event,id in @log
    $(@id).html(table + '</table>')

class TimeEvent
  constructor: (@note) ->
    @date = new Date
    @time = 0
    @diff = 0
    @cast = 1 #TODO this should be some kinda default?
    ###
    @diff  = NULL
    @_diff = NULL
    @dist  = NULL
    @_dist = NULL
    @cast  = NULL
    @_cast = NULL
    ###
  
  diff_in_min: ->
    @diff / 60

  diff_in_hr: ->
    @diff/(60*60)

  cast_in_sec: ->
    @cast/(60*60)

  calculate: ->
    # fill in all the _* vars 
    # CAST = dist / diff
    @_dist = @cast * @.diff_in_hr() if @cast? and @diff?
    @_cast = @dist / @.diff_in_hr() if @dist? and @diff?

class HeartBeat
  constructor: (@id,@interval,@action) ->
    @setUpdateInterval()
    
  update: ->
    $(@id).html( @action() )

  setUpdateInterval: ->
    setInterval( @update.bind(this), @interval)

class CLI
  # TODO I would rather have this become a hash->switch thing
  constructor: (@selector, @events) ->
    $( @selector ).keypress (event) =>
      current_value = $(@selector).val()

      if @events.keys[event.which]
        if typeof  @events.keys[event.which] == 'function'
          @events.keys[event.which]( event )
        else
          console.info('THIS HAS NOT YET BEEN IMPLIMENTED')
      else if @events.values[ current_value ]
        if typeof @events.values[ current_value ] == 'function'
          @events.values[ current_value ]( event )
          msg = "key match for #{current_value}"
          console.info(msg)
        else
          console.info('THIS HAS NOT YET BEEN IMPLIMENTED')
      else if @events.default
        @events.default( event )
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
                        [junk,id,method,value] = $('#buffer').val().match(/^\s*(\d*)([a-z]+):?(.*)/)
                        switch method
                          when 'rm' then e.log.splice(id,1)
                          when 'reset' then e.log = []
                          when 'update' then e.display()
                          else
                            id = e.log.length - 1 unless id.length
                            it = e.log[id]
                            if typeof it[method] is 'function' then it[method](value) else it[method] = value
                            it.calculate()
                        e.display()
                        buffer.clear()
                  )
  clock_tod     = new HeartBeat('#tod'               , 50 , -> HMC(new Date) )
  current_cast  = new HeartBeat( '#current_cast'     , 100, -> e.last()?.cast )
  expected_dist = new HeartBeat( '#expected_distance', 100, -> 
                                                              now     = new Date
                                                              since   = now - e.last()?.date # mseconds
                                                              covered = e.last()?.cast * (since / (1000*60*60))
                                                              (parseFloat(e.last()?.dist) + covered).toFixed(3)
                               )
  alert 'ready'
