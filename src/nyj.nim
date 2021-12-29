import ecs, fau/presets/[basic, effects], fau/util/util, math, random

static: echo staticExec("faupack -p:../assets-raw/sprites -o:../assets/atlas")

#palette
const
  col1 = %"110f25"
  col2 = %"4f6b7a"
  col3 = %"a7c6c5"

const 
  playerSpeed = 80f
  targetHeight = 300 #TODO unused
  targetWidth = 600

var player: EntityRef

defineEffects:
  bubble(lifetime = 1f):
    let off = vec2(0f, e.fin.powout(3f) * 7f)
    poly(e.pos + off, 10, 4f + 4f * e.fin.pow(4f), stroke = 2f * e.fout, color = col3)
    fillCircle(e.pos + vec2(1.1f) + off, 2f * e.fout, color = col3)

registerComponents(defaultComponentOptions):
  type
    Vel = object
      vec: Vec2
      rot: float32
      bub: float32
      moveTime: float32
    
    Player = object

makeTimedSystem()

sys("move", [Player, Vel, Pos]):
  all:
    let vec = vec2(axis(keyA, keyD), axis(keyS, keyW)).lim(1f) * playerSpeed * fau.delta
    if vec.len > 0:
      item.vel.rot = aapproach(item.vel.rot, vec.angle, 6f * fau.delta)
    
    item.vel.vec *= (1f - fau.delta * 4f)

    let base = vec.angled(item.vel.rot)
    if vec.len > 0: item.vel.vec = vec

    item.pos.x += item.vel.vec.x
    item.pos.y += item.vel.vec.y

    if vec.len > 0:
      item.vel.moveTime += fau.delta
      incTimer(item.vel.bub, 3f / 60f):
        effectBubble(item.pos.vec2 + vec2l(item.vel.rot, 11f) + randVec(7f))

sys("draw", [Main]):
  fields:
    buffer: Framebuffer

  init:
    player = newEntityWith(Vel(), Pos(), Player())
    sys.buffer = newFramebuffer()

  start:
    if keyEscape.tapped: quitApp()

    let scl = fau.size.x / targetWidth.float32#fau.size.y / targetHeight.float32

    sys.buffer.clear(col1)
    sys.buffer.resize((fau.size / scl).vec2i)
    
    fau.cam.update(fau.size / scl, player.fetch(Pos).vec2)
    fau.cam.use()

    drawBuffer(sys.buffer)
  
  finish:
    discard

template randRect(amount: int, seed: int, mutator, code: untyped) =
  block:
    let view = fau.cam.viewport.grow(fau.cam.size.x)
    let r = 1000f

    var ra {.inject.} = initRand(seed)

    for i in 0..<amount:
      var pos {.inject.} = vec2(ra.rand(-r..r), ra.rand(-r..r)) + vec2(fau.time * 4f, sin(fau.time, ra.rand(0.7f..1.5f), ra.rand(0f..4f)))
      pos += mutator
      pos -= view.pos
      pos = vec2(pos.x.emod view.w, pos.y.emod view.h)
      pos += view.pos

      code

sys("particles", [Main]):
  start:
    let 
      fish = "fish".patch
      fish2 = "xenofish".patch
      bubble = "bubble".patch

    randRect(45, 1):
      vec2(sin(fau.time, ra.rand(0.7f..1.5f), ra.rand(0f..4f)), fau.time * ra.rand(0.9f..4f) * 4f)
    do:
      draw(bubble, pos, scl = vec2(ra.rand(0.6f..1.2f)), color = col2)

    randRect(30, 2):
      vec2(fau.time * ra.rand(1f..4f) * 1f, sin(fau.time, ra.rand(0.7f..1.5f), ra.rand(0f..4f)))
    do:
      draw(fish, pos, scl = vec2(-1f + sin(fau.time, ra.rand(0.1f..0.3f), 0.06f), 1f) / 2f, color = col2)

    randRect(45, 3):
      vec2(fau.time * ra.rand(1f..4f) * 3f, sin(fau.time, ra.rand(0.7f..1.5f), ra.rand(0f..4f)))
    do:
      draw(if ra.rand(1f) > 0.8: fish2 else: fish, pos, scl = vec2(-1f + sin(fau.time, ra.rand(0.1f..0.3f), 0.06f), 1f), mixcolor = col2)


sys("drawPlayer", [Player, Pos, Vel]):
  all:
    draw("player".patch, item.pos.vec2, rotation = item.vel.rot, scl = vec2(1f + sin(item.vel.moveTime, 0.1f, 0.13f), -(item.vel.rot >= 90f.rad and item.vel.rot < 270f.rad).sign), mixColor = col3)

makeEffectsSystem()

sys("endDraw", [Main]):
  start:
    drawBufferScreen()
    sysDraw.buffer.blit()

launchFau("New Year's Jam 2021")
