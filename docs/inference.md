# Which build is this character? (feasibility, not dominance)

Written 4 November 2026, after the first real character: a Hardcore Paladin who
followed a levelling guide that starts with 5 points in Holy, so the first
version said Holy, though the player is a Retribution Paladin. The code is
`Guide.lua` (`G.reachable`, `G.open`, `G.resolve`); the sim has the cases.

## What was wrong

The first rule read the tree with most points as the build. Any build whose first
points are off its own tree (a common levelling order) was read as the wrong
one. It also let the points outrank a role the player had not even been asked
about. Both are the same mistake: points are evidence of what a character has
done so far, not of what it is going for.

## The rule

A build needs a number of the 51 points in its own tree (`G.required`: what the
deepest talent of that tree asks of it, plus the point it takes itself, so 31
for a tree whose deepest talent is at row 7: read off the talents' `req`, not
off the path, which may put 32 there) and may spend the rest anywhere. So a build is **reachable** while the points spent outside its tree
are no more than the rest (20 of 51). Five points in Holy rule out nothing.
Twenty keep Retribution open, twenty-one close it. This is checked per build
from the points, never from "most points", and it does not depend on the level:
`off <= 51 - required` is the same test as "the points left can still fill the
tree".

1. **A role first.** When a role is chosen (or a build is picked, which has a
   role) the candidates are that role's builds only. A Damage Paladin can only be
   Retribution, whatever the points.
2. **A pick is a pick.** A picked build is the page, whatever the points do. It
   is a drift only when the build can no longer be reached, never for a few
   early points off its path (the old path tolerance is gone).
3. **No pick, no role.** Count the reachable builds of the class.
   - One: the points tell, and the header says "Following your points."
   - Several: the points do not tell. The page shows the first build in the
     writer's order, the header says "Guessing from your points.", and the page
     asks: "Your points leave Retribution, Holy and Protection open. Which are
     you going for?", with the roles the open builds have as buttons. A role
     chosen with several builds still open asks for the build ("Use Fury").
   - None open in the role: if another role's build is open the page offers the
     switch ("None of your role's builds can be reached by your points. These
     points look more like a healer than a damage build. Switch your role to
     Heal?"), the role never switched by itself. If nothing is open anywhere the
     page says so ("Your points are split between Arms and Protection, so none
     of the builds fits them. This page shows the nearest, Arms."; a picked build
     stays: "...This page stays on Arms, the build you picked."). The nearest is
     by path (`G.differ`). A tree with no points is never part of a split.
4. **Drift** (a picked build that can no longer be reached): said once, quietly.
   If a build of the same role is still open, the note offers it (Keep, Follow
   or My own way). If only another role's build is open, it offers the role
   (Switch or Stay), never switching by itself. A dismissal is kept by a marker
   (`driftSeen`) until the drift changes.
5. **A respec to zero** returns the group to the choose phase with the stored
   role kept: nothing is asked again, the advice shows.
6. **Your own way** has no drift, no question and no note.

## Roads: one recommended, the others recognised

A build may have several roads (another order of the same points, same role, same
tree). Which road a page advises is our decision, not the player's: the
`recommended` one, or on a Hardcore realm the `hardcoreRoad` where the research
gives one. The inference above is about builds and is untouched: reachability does
not look at the road. Within a build, `G.pickRoad` keeps the recommended road
unless the points clearly follow another road (nearest by path, not a tie): then
the page advises along that one and says so quietly. No drift, no nag.

## What the header says

"Following your pick." (a build chosen), "Following your points." (the points
leave one build open), "Guessing from your points." (several open), "Your own
way.", "Not chosen yet." (nothing spent). It is frozen with the build while the
window is open (`docs/architecture.md`, "What the page is for").

## What the sim holds (addon/test/sim.lua)

Role given (Damage with 5 Holy points: Retribution; Heal: Holy), role not given
(all three open, the page does not say Holy), the boundary (20 off-tree points
reachable, 21 not), only one build open (21 in Holy: Holy), a role whose
builds are all out of reach (shown with the nearest, said so), a picked build
that stays with harmless early points, a picked build unreachable with another
role open (a switch offered) and with the same role open (Follow offered), a
dismissal kept, a respec to zero, your own way, and the window's own pages for
the Paladin and the Mage.
