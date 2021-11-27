# JSON format of object tree

Compalang is parsed into tree of following structure. Note that this is JS/JSON.

```
{
  features: {
    feature_name: { params: { ... }, links: { .... } },
    feature_name: { params: { ... }, links: { .... } },
    feature_name: true,
    ...
  }
  params: {
    name: value,
    name: value,
    ...
  },
  links: {
    name: { from: linkstr, to: linkstr },
    name: { from: linkstr, to: linkstr },
    ....
  },
  children: {
    name: { ..object.. },
    name: { ..object.. },
  },  
}
```
