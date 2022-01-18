Here we test approach:

find-objs | filter | deploy-features;

Tasks:
1. Make every 2nd rect with a different color.
1.1 make every i-th rect of diff color.
2. Add to each rect a text inside with rect number.
3. Make rects clickable so they become...
   a) invisible
   b) bounced
4. Same as 3 but make possible to move mouse instead of click   
	5. Implement all above as tab screens .
	6. Apply effect (1) only if some checkbox is checked.
	OR
	5+6: Make these things 1-4 appear only if appropriate checkbox checked.
7. Same as 6, but control applance using i-slider which controls i in 1.1.
and detaches feature at all on i=0;

+ think on idea not to keep value in checkbox, but catch it's events
(from compose jetpack) - what does it means to us?