class EventLog
  constructor: (@id) ->
    this.log = []
    this.default_cast = 1

  add: (event) ->
    if typeof event == 'string'
      event = new TimeEvent(event) # assume that we passed a note
    else if event instanceof TimeEvent
      # do nothing as we have been passed a proper object
    else
      event = new TimeEvent('automated')

    prev = this.log[ this.log.length - 1]

    event.diff = event.time - this.log[ this.log.length - 1]?.time ? 0
    event.cast = prev?.cast ? this.default_cast

    this.log.push( event )

  display: ->
    table = '<table>'
    table += event.display(id) for event,id in this.log;
    $(this.id).html(table + '</table>')

  all: ->
    console.info(this)

class TimeEvent
  constructor: (@note) ->
    this.time = new Date
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

  display: (id) ->
    row = "<th>#{this.id}</th>"
    row += "<td>#{this.x}</td>" for x in ['note','cast','time','diff']
    return "<tr>#{row}</tr>"

class DecimalClock
  constructor: (@id,@interval) ->
    console.info( "new clock for #{this.id} ticks at #{this.interval}/1000")
    this.setUpdateInterval()
    
  update: ->
    C = new Date
    $(this.id).html( sprintf('%02d:%02d.%02d' \
                            , C.getHours()    \
                            , C.getMinutes()  \
                            , Math.ceil(C.getSeconds() * 100/60 + C.getMilliseconds() / 1000) \
                            ))
  setUpdateInterval: ->
    console.info('setting up interval')
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
