F-WARN-A5

Не добавлялся модификатор прозрачности к точкам.

points_vp positions=@line_coords_combined ~extravis title="Профиль: точки" color=[1,0,0] radius=15
          addons={ effect3d_opacity=0.7 }
          
долго мучился. оказалось ошибка в записи, правильно так:
points_vp positions=@line_coords_combined ~extravis title="Профиль: точки" color=[1,0,0] radius=15
          addons={ effect3d_opacity opacity=0.7 }
          
возможное решение - таки требовать фичу, даже когда просто параметры. например object.

