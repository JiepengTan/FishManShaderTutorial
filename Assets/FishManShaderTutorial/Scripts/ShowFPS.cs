using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShowFPS : MonoBehaviour {

    private float m_LastUpdateShowTime = 0f;  //上一次更新帧率的时间;  

    private float m_UpdateShowDeltaTime = 0.01f;//更新帧率的时间间隔;  

    private int m_FrameUpdate = 0;//帧数;  

    public float m_FPS = 0;

    void Awake() {
        Application.targetFrameRate = 100;
    }

    // Use this for initialization  
    GUIStyle style;
    void Start() {
        style = new GUIStyle();
        m_LastUpdateShowTime = Time.realtimeSinceStartup;
    }

    // Update is called once per frame  
    void Update() {
        m_FrameUpdate++;
        if (Time.realtimeSinceStartup - m_LastUpdateShowTime >= m_UpdateShowDeltaTime) {
            m_FPS = m_FrameUpdate / (Time.realtimeSinceStartup - m_LastUpdateShowTime);
            m_FrameUpdate = 0;
            m_LastUpdateShowTime = Time.realtimeSinceStartup;
        }
    }
    public int fontSizeRel = 15;
    void OnGUI() {
        style.fontSize = fontSizeRel;
        GUI.Label(new Rect(0, 0, 300, 300), "FPS: " + m_FPS, style);
    }
}
