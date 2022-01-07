Here we test an ability to use features with their own params.
Example:
```
  feature1 p1=.. p2=.. {{ 
  	 feature2 p3=.. p31=... ; 
  	 feature3 p4=...; 
  }}
```
Here 
* p1 and p2 will be params of ENV,
* p3, p31 will be own params of feature2
* 4 will be own param of feature3.
