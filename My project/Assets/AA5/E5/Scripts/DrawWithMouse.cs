using UnityEngine;

public class DrawWithMouse : MonoBehaviour {

    //public
    public GameObject ObjectDrawer;
    
    public Shader drawShader;

    //private
    private RenderTexture _splatMap;
    private Material _snowMaterial, _drawMaterial;
    private RaycastHit _hit;

	void Start () {
        _drawMaterial = new Material(drawShader);
        _drawMaterial.SetVector("_Color", Color.red);
        _snowMaterial = GetComponent<MeshRenderer>().material;
        _splatMap = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGBFloat);
        _snowMaterial.SetTexture("_Splat", _splatMap);
    }
	

	void Update () 
    {
        if (Physics.Raycast(ObjectDrawer.transform.position, ObjectDrawer.transform.TransformDirection(Vector3.down), out _hit))
        {
            _drawMaterial.SetVector("_Coordinate", new Vector4(_hit.textureCoord.x, _hit.textureCoord.y, 0, 0));
            RenderTexture temp = RenderTexture.GetTemporary(_splatMap.width, _splatMap.height, 0, RenderTextureFormat.ARGBFloat);
            Graphics.Blit(_splatMap, temp);
            Graphics.Blit(temp, _splatMap, _drawMaterial);
            //borrada frame el temp
            RenderTexture.ReleaseTemporary(temp);
        }
    }

    private void OnGUI()
    {
        GUI.DrawTexture(new Rect(0, 0, 256, 256), _splatMap, ScaleMode.ScaleToFit, false, 1);
    }
}
