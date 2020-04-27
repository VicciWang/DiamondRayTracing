using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ButtonManager : MonoBehaviour
{
    public List<Button> buttons = new List<Button>();

    public List<Slider> Gem1 = new List<Slider>();
    public List<Slider> Gem2 = new List<Slider>();
    public List<Slider> Diamond = new List<Slider>();
    public Slider Bounce;
    public Text bounceText;

    public Material mat;

    private Vector4 Gem1Color;
    private Vector4 Gem2Color;
    private Vector4 DiamondCol;
    private void Start()
    {
        //add button listener
        for (int i = 0; i < buttons.Count; i++)
        {
            int index = i;
            buttons[i].onClick.AddListener(delegate ()
            {
                ChangeCamera(index);
            });
        }

        //add gem and diamonds sliders listener
        for(int i = 0; i < Gem1.Count; i++)
        {
            Gem1[i].onValueChanged.RemoveAllListeners();
            int index = i;
            Gem1[i].onValueChanged.AddListener(delegate
            {
                ChangeColor1(index);
            });
        }
        for (int i = 0; i < Gem2.Count; i++)
        {
            Gem2[i].onValueChanged.RemoveAllListeners();
            int index = i;
            Gem2[i].onValueChanged.AddListener(delegate
            {
                ChangeColor2(index);
            });
        }
        for (int i = 0; i < Diamond.Count; i++)
        {
            Diamond[i].maxValue = 3;
            Diamond[i].minValue = 2;
            Diamond[i].onValueChanged.RemoveAllListeners();
            int index = i;
            Diamond[i].onValueChanged.AddListener(delegate
            {
                ChangeColor3(index);
            });
        }
        Bounce.onValueChanged.AddListener(delegate
        {
            Bounce.minValue = 1;
            Bounce.maxValue = 10;
            MaxBounce();
        });
    }

    private void MaxBounce()
    {
        int b;
        b = (int)Bounce.value;
        bounceText.text = b.ToString();
        mat.SetInt("_MaxBounce", b);
    }

    private void ChangeColor1(int index)
    {
        Debug.Log(index);
        if(index == 0)
            Gem1Color.x = Gem1[index].value;
        if (index == 1) 
            Gem1Color.y = Gem1[index].value;
        if (index == 2)
            Gem1Color.z = Gem1[index].value;

        mat.SetColor("_RefractColor", Gem1Color);
    }
    private void ChangeColor2(int index)
    {
        Debug.Log(index);
        if (index == 0)
            Gem2Color.x = Gem2[index].value;
        if (index == 1)
            Gem2Color.y = Gem2[index].value;
        if (index == 2)
            Gem2Color.z = Gem2[index].value;

        mat.SetColor("_ReflectColor", Gem2Color);
    }
    private void ChangeColor3(int index)
    {
        if (index == 0)
            DiamondCol.x = Diamond[index].value;
        if (index == 1)
            DiamondCol.y = Diamond[index].value;
        if (index == 2)
            DiamondCol.z = Diamond[index].value;

        mat.SetVector("_DiamondIndex", DiamondCol);
    }
    void ChangeCamera(int number)
    {
        //pass button number to animate camera
        CameraRotation.count = number;
    }
}
