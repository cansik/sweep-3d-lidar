using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Orbit : MonoBehaviour {

	public GameObject Target;
	public float SpeedMod = 10.0f; 
	private Vector3 _point;
 
	void Start () {
		_point = Target.transform.position;
		transform.LookAt(_point);
	}
 
	void Update () {
		transform.RotateAround (Target.transform.position, Vector3.up, SpeedMod * Time.deltaTime);  
	}
}
