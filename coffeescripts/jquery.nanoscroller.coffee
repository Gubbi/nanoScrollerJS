(($, window, document) ->

  SCROLLBAR  = 'scrollbar'
  SCROLL     = 'scroll'
  MOUSEDOWN  = 'mousedown'
  MOUSEMOVE  = 'mousemove'
  MOUSEWHEEL = 'mousewheel'
  MOUSEUP    = 'mouseup'
  RESIZE     = 'resize'
  DRAG       = 'drag'
  UP         = 'up'
  PANEDOWN   = 'panedown'
  DOMSCROLL  = 'DOMMouseScroll'
  DOWN       = 'down'
  WHEEL      = 'wheel'

  getScrollbarWidth = ->
    outer                = document.createElement 'div'
    outer.style.position = 'absolute'
    outer.style.width    = '100px'
    outer.style.height   = '100px'
    outer.style.overflow = 'scroll'
    document.body.appendChild outer
    noscrollWidth  = outer.offsetWidth
    yesscrollWidth = outer.scrollWidth
    document.body.removeChild outer
    noscrollWidth - yesscrollWidth

  class NanoScroll

    constructor: (@el) ->
      @generate()
      @scrollCheck()
      @createEvents()
      @addEvents()
      @reset()

    createEvents: ->
      ## filesize reasons
      @events =
        down: (e) =>
          @isDrag  = true
          if @scrollType is 'vertical'
            @offsetY = e.clientY - @slider.offset().top
          else if @scrollType is 'horizontal'
            @offsetY = e.clientX - @slider.offset().left
          @pane.addClass 'active'
          $(document).bind MOUSEMOVE, @events[DRAG]
          $(document).bind MOUSEUP, 	@events[UP]
          false

        drag: (e) =>
          if @scrollType is 'vertical'
            @sliderY = e.clientY - @el.offset().top - @offsetY
          if @scrollType is 'horizontal'
            @sliderY = e.clientX - @el.offset().left - @offsetY
          @scroll()
          false

        up: (e) =>
          @isDrag = false
          @pane.removeClass 'active'
          $(document).unbind MOUSEMOVE, @events[DRAG]
          $(document).unbind MOUSEUP, 	@events[UP]
          false

        resize: (e) =>
          @reset()
          return

        panedown: (e) =>
          if @scrollType is 'vertical'
            @sliderY = e.clientY - @el.offset().top - @sliderH * 0.5
          if @scrollType is 'horizontal'
            @sliderY = e.clientX - @el.offset().left - @sliderH * 0.5
          @scroll()
          @events.down e
          return

        scroll: (e) =>
          content = @content[0]
          return if @isDrag is true
          if @scrollType is 'vertical'
            top = content.scrollTop / (content.scrollHeight - content.clientHeight) * (@paneH - @sliderH)
            @slider.css top: top + 'px'
          if @scrollType is 'horizontal'
            left = content.scrollLeft / (content.scrollWidth - content.clientWidth) * (@paneH - @sliderH)
            @slider.css left: left + 'px'
          return

        wheel: (e) =>
          @sliderY +=  -e.wheelDeltaY || -e.delta
          @scroll()
          return false
      return

    addEvents: ->
      events = @events
      pane = @pane
      $(window).bind RESIZE  , events[RESIZE]
      @slider.bind MOUSEDOWN , events[DOWN]
      pane.bind MOUSEDOWN   , events[PANEDOWN]
      @content.bind SCROLL   , events[SCROLL]

      if window.addEventListener
        pane = pane[0]
        pane.addEventListener MOUSEWHEEL , events[WHEEL] , false
        pane.addEventListener DOMSCROLL  , events[WHEEL] , false
      return

    removeEvents: ->
      events = @events
      pane = @pane
      $(window).unbind RESIZE  , events[RESIZE]
      @slider.unbind MOUSEDOWN , events[DOWN]
      pane.unbind MOUSEDOWN    , events[PANEDOWN]
      @content.unbind SCROLL   , events[SCROLL]

      if window.addEventListener
        pane = pane[0]
        pane.removeEventListener MOUSEWHEEL , events[WHEEL] , false
        pane.removeEventListener DOMSCROLL  , events[WHEEL] , false
      return

    generate: ->
      @el.append '<div class="pane"><div class="slider"></div></div>'
      @content = $ @el.children()[0]
      @slider  = @el.find '.slider'
      @pane    = @el.find '.pane'
      @scrollW = getScrollbarWidth()
      @scrollW = 0 if @scrollbarWidth is 0
      @content.css
        right  : -@scrollW + 'px'
      return

    scrollCheck: ->
      content = @content[0]
      @paneH  = @pane.outerHeight()
      console.log @paneH, content.scrollHeight
      if @paneH >= content.scrollHeight
        @el.addClass 'horizontal'
        @content.css
          bottom : -@scrollW + 'px'
          right  : 'auto'

        @paneH = content.clientWidth
        console.log @paneH, content.scrollWidth
        if @paneH >= content.scrollWidth
          @scrollType = 'none'
          @el.removeClass 'horizontal'
          @content.css
            right  : -@scrollW + 'px'
            bottom : 'auto'
        else
          @scrollType = 'horizontal'
      else
        @scrollType = 'vertical'

    reset: ->
      if @isDead is true
        @isDead = false
        @pane.show()
        @addEvents()

      if @scrollType is 'none'
        @pane.hide()
      else
        content = @content[0]
        if @scrollType is 'vertical'
          @contentH  = content.scrollHeight + @scrollW
          @paneH     = @pane.outerHeight()
        else
          @contentH  = content.scrollWidth + @scrollW
          @paneH     = content.clientWidth

        @sliderH   = @paneH / @contentH * @paneH
        @sliderH   = Math.round @sliderH
        @scrollH   = @paneH - @sliderH

        if @scrollType is 'vertical'
          @slider.height 	@sliderH
          @diffH = content.scrollHeight - content.clientHeight
        else
          @slider.width   @sliderH
          @diffH = content.scrollWidth - content.clientWidth

        @pane.show()
      return

    scroll: ->
      @sliderY    = Math.max 0, @sliderY
      @sliderY    = Math.min @scrollH, @sliderY
      scrollValue = @paneH - @contentH + @scrollW
      scrollValue = scrollValue * @sliderY / @scrollH
      # scrollvalue = (paneh - ch + sw) * sy / sw
      if @scrollType is 'vertical'
        @content.scrollTop -scrollValue
        @slider.css top: @sliderY
      if @scrollType is 'horizontal'
        @content.scrollLeft -scrollValue
        @slider.css left: @sliderY

    scrollBottom: (offsetY) ->
      diffH = @diffH
      scrollTop = @content[0].scrollTop
      @reset()
      return if scrollTop < diffH and scrollTop isnt 0
      @content.scrollTop @contentH - @content.height() - offsetY
      return

    scrollTop: (offsetY) ->
      @reset()
      @content.scrollTop offsetY + 0
      return

    stop: ->
      @isDead = true
      @removeEvents()
      @pane.hide()
      return


  $.fn.nanoScroller = (options) ->
    options or= {}
    # scumbag IE7
    if not ($.browser.msie and parseInt($.browser.version, 10) < 8)
      scrollbar = @data SCROLLBAR
      if scrollbar is undefined
        scrollbar = new NanoScroll this
        @data SCROLLBAR, scrollbar

      return scrollbar.scrollBottom(options.scrollBottom) if options.scrollBottom
      return scrollbar.scrollTop(options.scrollTop)       if options.scrollTop
      return scrollbar.scrollBottom(0)                    if options.scroll is 'bottom'
      return scrollbar.scrollTop(0)                       if options.scroll is 'top'
      return scrollbar.stop()                             if options.stop
      scrollbar.reset()
    return
  return

)(jQuery, window, document)
