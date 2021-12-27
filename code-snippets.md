
## Rendering params of objects
```
screen auto_activate {
      column gap="0.5em" {
        dom tag="h3" innerText="Visual settings" style="margin:0;";
        render-guis objects=@find_objs->output opened=true;
        find_objs:  find-objects pattern="** myvisual";
      };
}
```