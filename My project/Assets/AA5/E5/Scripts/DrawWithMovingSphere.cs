using UnityEngine;

public class DrawWithSphereVolumeContact : MonoBehaviour
{
    public Shader _drawShader;
    public Transform _sphere;
    public int gridSteps = 5;
    public float _brushStrength = 1f;
    [Range(0, 1f)]public float displacement = 0.3f;
    public RenderTexture _splatmap;
    private Material _drawMaterial, _targetMaterial;

    void Awake()
    {
        _drawMaterial = new Material(_drawShader);
        _drawMaterial.SetVector("_Color", Color.red);

        _targetMaterial = GetComponent<MeshRenderer>().material;
        ClearRenderTexture(_splatmap, Color.black);
        //_splatmap = new RenderTexture(128, 128, 0, RenderTextureFormat.ARGBFloat);
        _targetMaterial.SetTexture("_Splat", _splatmap);

    }


    void Update()
    {
        if (_sphere == null) return;

        float radius = _sphere.localScale.x * 0.5f;
        Vector3 center = _sphere.position;

        if (!Physics.CheckSphere(center, radius)) return;

        Vector3 rayDir = Vector3.down;
        float rayLength = radius + 0.3f + displacement;

        for (int x = -gridSteps; x <= gridSteps; x++)
        {
            for (int z = -gridSteps; z <= gridSteps; z++)
            {
                Vector2 offset = new Vector2(x, z) / gridSteps * radius;
                float distanceFromCenter = offset.magnitude;

                if (distanceFromCenter > radius) continue;

                float localHeight = Mathf.Sqrt(radius * radius - distanceFromCenter * distanceFromCenter);
                float dynamicRayLength = localHeight + 0.3f + displacement;

                Vector3 origin = center + new Vector3(offset.x, 0.2f, offset.y);
                bool didHit = Physics.Raycast(origin, Vector3.down, out RaycastHit hit, dynamicRayLength);

                Color rayColor = didHit ? (hit.collider.gameObject == gameObject ? Color.green : Color.yellow) : Color.red;
                Debug.DrawRay(origin, Vector3.down * dynamicRayLength, rayColor, 0f, false);

                if (didHit)
                {
                    Vector2 uv = hit.textureCoord;
                    _drawMaterial.SetVector("_Coordinate", new Vector4(uv.x, uv.y, 0, 0));
                    float diameter = _sphere.localScale.x;
                    _drawMaterial.SetFloat("_Size", diameter);
                    _drawMaterial.SetFloat("_Strenght", _brushStrength);

                    RenderTexture temp = RenderTexture.GetTemporary(_splatmap.width, _splatmap.height, 0, RenderTextureFormat.ARGBFloat);
                    Graphics.Blit(_splatmap, temp);
                    Graphics.Blit(temp, _splatmap, _drawMaterial);
                    RenderTexture.ReleaseTemporary(temp);
                }
            }
        }
    }
    void ClearRenderTexture(RenderTexture rt, Color clearColor)
    {
        RenderTexture active = RenderTexture.active;
        RenderTexture.active = rt;
        GL.Clear(true, true, clearColor);
        RenderTexture.active = active;
    }
    private void OnGUI()
    {
        GUI.DrawTexture(new Rect(0, 0, 128, 128), _splatmap, ScaleMode.ScaleToFit, false, 1);
    }
}
