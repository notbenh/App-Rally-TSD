### TODO to keep sprintf or not? currently does not do n.nf correctly 
zpad = (dig,pad) ->
  padS = pad.toString()
  digS = dig.toString()

  if padS.match(/[.]/) 
    [dig1,dig2] = digS.split(/[.]/,2)
    [pad1,pad2] = padS.split(/[.]/,2)
    return zpad(dig1,pad1) + '.' + zpad(dig2.toString().substr(0,pad2),pad2)
  else
    if digS.length < pad
      digS = "0#{digS}" for x in [pad - digS.length .. 1]

    digS
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
    this.log = []

  add: (event) ->
    if typeof event == 'string'
      event = new TimeEvent(event) # assume that we passed a note
    else if event instanceof TimeEvent
      # do nothing as we have been passed a proper object
    else
      event = new TimeEvent('automated')

    prev = this.log[ this.log.length - 1]

    event.time = event.date - this.log[0].date if this.log[0]?
    event.diff = event.date - this.log[ this.log.length - 1].date if this.log[ this.log.length - 1]?
    event.cast ?= prev?.cast 

    this.log.push( event )

  display: ->
    table = """
            <table>
              <tr>
                <th>id</th>
                <th>split</th>
                <th>lap</th>
                <th>cast</th>
                <th>note</th>
              </tr>
            """
    table += """
               <tr>
                 <th>#{id}</th>
                 <td>#{UTC_HMC( new Date(event.time)) }</td>
                 <td>#{UTC_HMC( new Date(event.diff)) }</td>
                 <td>#{event.cast}</td>
                 <td>#{event.note}</td>
               </tr>
             """ for event,id in this.log
    $(this.id).html(table + '</table>')

  all: ->
    console.info(this)

class TimeEvent
  constructor: (@note) ->
    this.date = new Date
    this.time = 0
    this.diff = 0
    this.cast = 1 #TODO this should be some kinda default?
    ###
    this.diff  = NULL
    this._diff = NULL
    this.dist  = NULL
    this._dist = NULL
    this.cast  = NULL
    this._cast = NULL
    ###
  
  diff_in_min: ->
    this.diff / 60

  diff_in_hr: ->
    this.diff/(60*60)

  cast_in_sec: ->
    this.cast/(60*60)

  calculate: ->
    # fill in all the _* vars 
    # CAST = dist / diff

class DecimalClock
  constructor: (@id,@interval) ->
    # console.info( "new clock for #{this.id} ticks at #{this.interval}/1000")
    this.setUpdateInterval()
    
  update: ->
    $(this.id).html( HMC(new Date) )

  setUpdateInterval: ->
    setInterval( @update.bind(this), this.interval) # you have to bind this to a reference =(



class CLI
  # TODO I would rather have this become a hash->switch thing
  constructor: (@selector, @events) ->
    $( this.selector ).keypress (event) =>
      current_value = $(this.selector).val()

      if this.events.keys[event.which]
        if typeof  this.events.keys[event.which] == 'function'
          this.events.keys[event.which]( event )
        else
          console.info('THIS HAS NOT YET BEEN IMPLIMENTED')
      else if this.events.values[ current_value ]
        if typeof this.events.values[ current_value ] == 'function'
          this.events.values[ current_value ]( event )
          msg = "key match for #{current_value}"
          console.info(msg)
        else
          console.info('THIS HAS NOT YET BEEN IMPLIMENTED')
      else if this.events.default
        this.events.default( event )
      else
        # console.info( 'ultra default' )

    $( this.selector ).focus()

  me: ->
    return $(this.selector)

  val: ->
    return $(this.selector).val()

  clear: ->
    $(this.selector).val('')

  mk_ev: ->
    return (event) -> console.info(event.which)

## --------------------------------------------------------------------------- ##


$ ->
  log = new EventLog('#log')

  buffer = new CLI( '#buffer' ,
                    keys  :
                      32: -> 
                        log.add()
                        log.display()
                        buffer.clear()
                      13: -> 
                        # TODO this should not directly access 
                        [junk,id,method,value] = $('#buffer').val().match(/^\s*(\d*)([a-z]+)(.*)/)
                        id = -1 unless id.length
                        console.info([id,method,value])

                        ###
                        match = $('#buffer').val().match(/^\s*(\d*)([a-z]+)(.*)/)
                        match.shift() # remove that pointless copy of what we just had?!?
                        match[0] = -1 unless match[0].length
                        console.info(match)
                        ###
                        buffer.clear()
                        console.info('ENTER')
                    values:
                      'monkey': -> console.info('MONKEY')
                    default: -> console.info(event.which)
                  )

  clock_tod = new DecimalClock('#tod',50)
  alert 'ready'
