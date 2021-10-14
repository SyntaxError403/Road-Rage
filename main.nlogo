globals [
  selected-car   ; the currently selected car
  lanes          ; a list of the y coordinates of different lanes
  road-ragers
  cops
  driver-in-view

]


turtles-own [
  speed         ; the current speed of the car
  top-speed     ; the maximum speed of the car (different for all cars)
  target-lane   ; the desired lane of the car
  patience      ; the driver's current level of patience
  road-rager?
  cop?
  encounters
  distance-traveled
  laps
  real-distance
  starting-point
  dead?
  done?
]

patches-own
[vision]

to setup
  clear-all
  set-default-shape turtles "car"
  draw-road
  create-or-remove-cars
  set selected-car one-of turtles
  ask selected-car [ set color white ]
  select-cops
  select-road-rage-drivers

  ;finish-line
  reset-ticks
end


to calculate-distance
  set distance-traveled  [xcor] of selected-car - [starting-point] of selected-car
  if  distance-traveled <= 0 [set laps laps + 1 ]
  set real-distance laps * 33
  if real-distance > distance-to-travel [set done? true]
end

to finish-line
  ask turtles[
    if distancexy -20 0 > 1
   ; or any? turtles-on patch 18 1
   ; or any? turtles-on patch 18 -3
      [set color green]
  ]

end


to select-cops
   let current-number 0
    loop [
      if current-number = number-of-cops [ stop ]
      set cops one-of turtles
      ask cops [set color blue]
      ask cops [set cop? true]
      set current-number  current-number + 1
  ]
end


to select-road-rage-drivers
    let current-number 0
    loop [
      if current-number = initial-number-of-road-rage-drivers [ stop ]
      ;select "one-of? random turtle out of population
      set road-ragers one-of turtles with [cop? = false]
      ask road-ragers [set color red]
      ask road-ragers [set speed .5 ]
      ask road-ragers [set top-speed .9]
      ask road-ragers [set road-rager? true]
      set current-number  current-number + 1
    ]

end

to road-rage

  set patience 0
  set heading 90
  speed-up-car ; we tentatively speed up, but might have to slow down
  let blocking-cars other turtles in-cone (1 + speed) 180 with [ y-distance <= 1 ]
  let blocking-car min-one-of blocking-cars [ distance myself ]
 ; if y-distance <= 0 [die]
  if blocking-car != nobody [
    ; match the speed of the car ahead of you and then slow
    ; down so you are driving a bit slower than that car.
    set speed [ speed ] of blocking-car + random .5

    ;cut ahead

    choose-new-lane

    ;if xcor - distance min-one-of blocking-cars  [distance myself] > 1 [set number-of-cars number-of-cars - 1 die]

  ]

  if turtle 0 != nobody [
  calculate-distance
  ]

  if blocking-car = nobody[
  set color red
  ]

  forward speed

  ask turtles with [ patience <= 0 ] [ choose-new-lane ]

end

to create-or-remove-cars

  ; make sure we don't have too many cars for the room we have on the road
  let road-patches patches with [ member? pycor lanes ]
  if number-of-cars > count road-patches [
    set number-of-cars count road-patches
  ]

  create-turtles (number-of-cars - count turtles) [
    set size .4
    set color car-color
    move-to one-of free road-patches
    set target-lane pycor
    set heading 90
    set top-speed 0.5 + random-float 0.5
    set speed 0.5
    set distance-traveled 0
    set road-rager? false
    set cop? false
    set starting-point xcor
    set dead? false
    set done? false
    set patience random max-patience
  ]

  if count turtles > number-of-cars [
    let n count turtles - number-of-cars
    ask n-of n [ other turtles ] of selected-car [ die ]
  ]


end

to-report free [ road-patches ] ; turtle procedure
  let this-car self
  report road-patches with [
    not any? turtles-here with [ self != this-car ]
  ]
end

to draw-road
  ask patches [
    ; the road is surrounded by green grass of varying shades
    set pcolor green - random-float 0.5
  ]
  set lanes n-values number-of-lanes [ n -> number-of-lanes - (n * 2) - 1 ]
  ask patches with [ abs pycor <= number-of-lanes ] [
    ; the road itself is varying shades of grey
    set pcolor grey - 2.5 + random-float 0.25
  ]
  draw-road-lines
end

to draw-road-lines
  let y (last lanes) - 1 ; start below the "lowest" lane
  while [ y <= first lanes + 1 ] [
    if not member? y lanes [
      ; draw lines on road patches that are not part of a lane
      ifelse abs y = number-of-lanes
        [ draw-line y yellow 0 ]  ; yellow for the sides of the road
        [ draw-line y white 0.5 ] ; dashed white between lanes
    ]
    set y y + 1 ; move up one patch
  ]
end

to draw-line [ y line-color gap ]
  ; We use a temporary turtle to draw the line:
  ; - with a gap of zero, we get a continuous line;
  ; - with a gap greater than zero, we get a dasshed line.
  create-turtles 1 [
    setxy (min-pxcor - 0.5) y
    hide-turtle
    set color line-color
    set heading 90
    repeat world-width [
      pen-up
      forward gap
      pen-down
      forward (1 - gap)
    ]
    die
  ]
end

to go
  create-or-remove-cars
  ask turtles with [road-rager? = false] [ move-forward ]
  ask turtles with [road-rager?] [ road-rage ]
  ask turtles with [ ycor != target-lane ] [ move-to-target-lane ]
  cop-vision
  tick
  if all? turtles [done?] [stop]
end

to move-forward ; turtle procedure
  set heading 90
  speed-up-car ; we tentatively speed up, but might have to slow down
  let blocking-cars other turtles in-cone (1 + speed) 180 with [ y-distance <= 1 ]
  let blocking-car min-one-of blocking-cars [ distance myself ]
 ; if y-distance <= 0 [die]
  if blocking-car != nobody [
    ; match the speed of the car ahead of you and then slow
    ; down so you are driving a bit slower than that car.
    set speed [ speed ] of blocking-car
    slow-down-car
   ; if xcor - distance min-one-of blocking-cars  [distance myself] < 1 [set number-of-cars number-of-cars - 1 die]
  ]
  ask turtles with [speed > 0]
    [calculate-distance]
  forward speed
end

to slow-down-car ; turtle procedure
  set speed (speed - deceleration)
  if speed < 0 [ set speed deceleration ]
  ; every time you hit the brakes, you loose a little patience
  set patience patience - 1
end

to speed-up-car ; turtle procedure
  set speed (speed + acceleration)
  if speed > top-speed [ set speed top-speed ]
end

to choose-new-lane ; turtle procedure
  ; Choose a new lane among those with the minimum
  ; distance to your current lane (i.e., your ycor).
  let other-lanes remove ycor lanes
  if not empty? other-lanes [
    let min-dist min map [ y -> abs (y - ycor) ] other-lanes
    let closest-lanes filter [ y -> abs (y - ycor) = min-dist ] other-lanes
    set target-lane one-of closest-lanes
    ask turtles with [road-rager? = false]
    [set patience max-patience]
  ]
end

to move-to-target-lane ; turtle procedure
  set heading ifelse-value target-lane < ycor [ 180 ] [ 0 ]
  let blocking-cars other turtles in-cone (1 + abs (ycor - target-lane)) 180 with [ x-distance <= 1 ]
  let blocking-car min-one-of blocking-cars [ distance myself ]
  ifelse blocking-car = nobody [
    forward 0.2
    set ycor precision ycor 1 ; to avoid floating point errors
  ] [
    ; slow down if the car blocking us is behind, otherwise speed up
    ifelse towards blocking-car <= 180 [ slow-down-car ] [ speed-up-car ]
  ]
end

to-report x-distance
  report distancexy [ xcor ] of myself ycor
end

to-report y-distance
  report distancexy xcor [ ycor ] of myself
end

to select-car
  ; allow the user to select a different car by clicking on it with the mouse
  if mouse-down? [
    let mx mouse-xcor
    let my mouse-ycor
    if any? turtles-on patch mx my [
      set selected-car one-of turtles-on patch mx my
      ask selected-car [ set color green ]
      display
    ]
  ]
end


to check-for-crash

end


to cop-vision
  draw-road
 ; display cop vision
  ask turtles with [cop? = true ]
  [ ask patches in-cone 3 60
   [ set pcolor red ]
    let blocking-cars other turtles in-cone 3 60
   ; (1 + speed) 180 with [ y-distance <= 3 ]
    let blocking-car min-one-of blocking-cars [ distance myself ]
    if blocking-car != nobody  [
      ask blocking-car [set pcolor green]]
  ]


end

to-report car-color
  ; give all cars a blueish color, but still make them distinguishable
  report one-of [ white ]
end

to-report number-of-lanes
  ; To make the number of lanes easily adjustable, remove this
  ; reporter and create222 a slider on the interface with the same
  ; name. 8 lanes is the maximum that currently fit in the view.
  report 3
end


; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.
