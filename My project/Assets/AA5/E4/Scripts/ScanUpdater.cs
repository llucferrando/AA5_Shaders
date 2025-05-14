using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

// -- Updates the origin position for scan origin

public class ScanUpdater : MonoBehaviour
{
    public PostProcessVolume volume;
    private PostProcessingScan scan;

    void Start()
    {
        volume.profile.TryGetSettings(out scan);
    }

    void Update()
    {
        if (scan != null)
        {
            scan._Origin.value = transform.position;
        }
    }
}
