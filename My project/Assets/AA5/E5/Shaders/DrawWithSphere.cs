using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DrawWithSphere : MonoBehaviour
{
    public Camera camera;
    public Shader drawShader;
    [Range(1,500)]
    public float _brushSize;
    [Range(0,1)]
    public float _brushStrength;

    private RenderTexture _splatmap;
    private Material _snowMaterial, _drawMaterial;
    private RaycastHit _hit;


    // Start is called before the first frame update
    void Start()
    {
        _drawMaterial = new Material(drawShader);
        _drawMaterial.SetVector("_Color", Color.red);

        _snowMaterial = GetComponent<MeshRenderer>().material;
        _splatmap = new RenderTexture(128, 128, 0, RenderTextureFormat.ARGBFloat);
        _snowMaterial.SetTexture("_Splat", _splatmap);
        
    }

    // Update is called once per frame
    void Update()
    {
       if(Input.GetKey(KeyCode.Mouse0))
        {
            if(Physics.Raycast(camera.ScreenPointToRay(Input.mousePosition),out _hit))
            {
                _drawMaterial.SetVector("_Coordinate", new Vector4(_hit.textureCoord.x, _hit.textureCoord.y, 0, 0));
                _drawMaterial.SetFloat("_Strenght", _brushStrength);
                _drawMaterial.SetFloat("_Size", _brushSize);
                RenderTexture temp = RenderTexture.GetTemporary(_splatmap.width, _splatmap.height, 0, RenderTextureFormat.ARGBFloat);
                Graphics.Blit(_splatmap, temp);
                Graphics.Blit(temp, _splatmap, _drawMaterial);
                RenderTexture.ReleaseTemporary(temp);  
            }
        }
    }

    private void OnGUI()
    {
        GUI.DrawTexture(new Rect(0, 0, 128, 128), _splatmap, ScaleMode.ScaleToFit, false, 1);
    }
}
