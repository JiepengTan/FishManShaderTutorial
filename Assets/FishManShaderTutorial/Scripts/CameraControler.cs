using UnityEngine;
using System.Collections;


public class CameraControler : MonoBehaviour {
    
    public float moveSpd = 10f;
    public float rotateSpd = 1f;
    //旋转变量;
    private float m_deltX = 0f;
    private float m_deltY = 0f;
    //缩放变量;
    private float m_distance = 10f;
    private float m_mSpeed = 5f;
    //移动变量;
    private Vector3 m_mouseMovePos = Vector3.zero;
    Camera camera;
    void Start() {
        camera = GetComponent<Camera>();
        if (camera == null) {
            enabled = false;
            return;
        }
    }

    void Update() {
        //鼠标右键点下控制相机旋转;
        if (Input.GetMouseButton(1)) {
            m_deltX += Input.GetAxis("Mouse X") * m_mSpeed * rotateSpd;
            m_deltY -= Input.GetAxis("Mouse Y") * m_mSpeed * rotateSpd;
            m_deltX = ClampAngle(m_deltX, -360, 360);
            m_deltY = ClampAngle(m_deltY, -70, 70);
            camera.transform.rotation = Quaternion.Euler(m_deltY, m_deltX, 0);
        }
        if (Input.GetMouseButton(2)) {
            transform.Translate(Vector3.left * Input.GetAxis("Mouse X"));
            transform.Translate(Vector3.down * Input.GetAxis("Mouse Y"));
        }
        //鼠标中键点下场景缩放;
        if (Input.GetAxis("Mouse ScrollWheel") != 0) {
            //自由缩放方式;
            m_distance = Input.GetAxis("Mouse ScrollWheel") * 10f;
            camera.transform.localPosition = camera.transform.position + camera.transform.forward * m_distance * moveSpd;
        }

        //相机复位远点;
        if (Input.GetKey(KeyCode.Space)) {
            m_distance = 10.0f;
            camera.transform.localPosition = new Vector3(0, m_distance, 0);
        }
    }

    //规划角度;
    float ClampAngle(float angle, float minAngle, float maxAgnle) {
        if (angle <= -360)
            angle += 360;
        if (angle >= 360)
            angle -= 360;

        return Mathf.Clamp(angle, minAngle, maxAgnle);
    }
}
