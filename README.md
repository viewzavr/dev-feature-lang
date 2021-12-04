# Vrungel

Visualizes scenes written in compalang language.

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


# Copyright

2021+ (c) Pavel Vasev. Available with MIT license.
