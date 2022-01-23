# Vrungel

Visualizes scenes written in compalang language.

# Prepare computer

For Vrungel to run, a NodeJS program should be installed on computer.
You may install NodeJS using installer from https://nodejs.org/en/download/.

# Prepare scene

Create a directory and put `main.cl` file into it.

# Run

Cd to directory and run:
```
npx vrungel
```

# Windows Explorer menu

"Open with Vrungel..." windows explorer menu is available. Use command:
* `npx -p vrungel vrungel-setup` - add menu.
* `npx -p vrungel vrungel-setup-off` - remove menu.

On Linux, this will add menu to GNOME Nautilus.


# Development

```
git clone https://github.com/viewzavr/vrungel.git
cd vrungel
git submodule update --init --recursive
npm install
npm start
```

# Thanks

The project is designed by Pavel Vasev.

Primary co-authors of this project are: Mikhail Bakhterev, Dmitry Manakov.

People influenced on the project:
Andrey Fedotov, 
Majid Forghani,
Ivan Kozmin, 
Yaroslav Kuznetsov, 
Valery Patsko, 
Denis Perevalov,
Dmitry Philonenko, 
Konstantin Ryabinin, 
Maria Vaseva,
Alexey Svalukhin.

Also thanks to colleagues of [Vladimir Averbukh](https://www.researchgate.net/profile/Vladimir-Averbukh)'s lab at Krasovskii Institute.

# Copyright

2022 (c) Pavel Vasev. Available with MIT license.
