using System;
using UnityEngine;

public class ThirdPersonUserControl : MonoBehaviour {
    public float moveSpd = 5;
    public float turnSpeed = 180;
    public float lerpSpd = 2f;
    public Camera cam;
    public Vector3 relSrcPos = new Vector3(0,7,-7);
    public Vector3 relTargetPos = new Vector3(0, 0, 7);
    float up;
    private void Update() {
        float h = Input.GetAxis("Horizontal");
        float v = Input.GetAxis("Vertical");
        bool crouch = Input.GetKey(KeyCode.C);
        up = 0;
        if (Input.GetKey(KeyCode.F)) {
            up = -1;
        }
        if (Input.GetKey(KeyCode.G)) {
            up = 1;
        }
        
        transform.Rotate(0, h * turnSpeed * Time.deltaTime, 0);
        transform.position += (v * transform.forward + up * transform.up) * moveSpd * Time.deltaTime;
        if (cam != null) {
            var camTran = cam.transform;
            var srcRot = camTran.rotation;
            var srcPos = camTran.position;
            var dstPos = transform.TransformPoint(relSrcPos);
            var targetPos = transform.TransformPoint(relTargetPos);
            camTran.position = dstPos;
            camTran.LookAt(targetPos);
            var dstRot = camTran.rotation;

            camTran.position = Vector3.Slerp(srcPos, dstPos, Time.deltaTime* lerpSpd);
            camTran.rotation = Quaternion.Slerp(srcRot, dstRot, Time.deltaTime* lerpSpd);
        }
    }
}