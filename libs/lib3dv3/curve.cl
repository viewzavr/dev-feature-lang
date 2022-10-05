//
// input - массив в котором 3ки чисел (или мб df?)
// t = время от 0 до 1
// выход
// output - массив из 3 чисел
feature "compute_curve" {
	cc: object
	output=(
		m_eval "(THREE, arr, t) => {
			//console.log('computacurva',t)
			//if (!THREE) return;
			//if (!arr) return;
			//if (!t) return;

			if (env.params.assigned_arr != arr) {
				let acc = [];
				if (arr.length < 3*2) return arr;
				for (let i=0; i<arr.length; i+=3) {
					acc.push( new THREE.Vector3( arr[i], arr[i+1], arr[i+2] ) );
				}
				let pipeSpline = new THREE.CatmullRomCurve3(acc);
				env.setParam('assigned_arr',arr);
				env.setParam('spline',pipeSpline);
			}
			let spline = env.params.spline;
			let pt = spline.getPoint( t );
			return [pt.x, pt.y, pt.z];

		}" (import_js (resolve_url "three.js/build/three.module.js")) @cc->input @cc->t;
	);
};

/*
// input - df с кол X Y Z и еще STEP
// самое сложное это STEP - тут идея взять алгоритм из camera_computer_splines
feature "compute_curve_df" {
cc:
	output=(
		m_eval "(THREE, df, t) => {
			//console.log('computacurva',t)
			//if (!THREE) return;
			//if (!arr) return;
			//if (!t) return;

			if (env.params.assigned_arr != arr) {
				let acc = [];
				if (arr.length < 3*2) return arr;
				for (let i=0; i<arr.length; i+=3) {
					acc.push( new THREE.Vector3( arr[i], arr[i+1], arr[i+2] ) );
				}
				let pipeSpline = new THREE.CatmullRomCurve3(acc);
				env.setParam('assigned_arr',arr);
				env.setParam('spline',pipeSpline);
			}
			let spline = env.params.spline;
			let pt = spline.getPoint( t );
			return [pt.x, pt.y, pt.z];

		}" (import_js (resolve_url "three.js/build/three.module.js")) @cc->input @cc->t;
	);
}
*/