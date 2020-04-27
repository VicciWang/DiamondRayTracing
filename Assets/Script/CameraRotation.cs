using System.Collections;
using System.Collections.Generic;
using System.Threading;
using UnityEngine;
using UnityEngine.UI;
public class CameraRotation : MonoBehaviour
{
    public Transform[] targets = new Transform[6];
    public float speed = 1;
    public float rotateSpeed = 10;
    public float timer = 2;
    static public int count = -1;

    public GameObject[] gameObjects = new GameObject[5];
    private Rigidbody[] rigidbodies = new Rigidbody[5];
    public Transform[] origins = new Transform[5];

    private void Start()
    {
        //get rigidbody in order to disable gravity
        for (int i = 0; i < rigidbodies.Length; i++)
        {
            rigidbodies[i] = gameObjects[i].GetComponent<Rigidbody>();
        }
    }
    private void Update()
    {
        //count determined by button number
        if (count != -1)
        {
            //translate camera and call for rotate diamond
            Vector3 dir = targets[count].position - this.transform.position;
            Vector3 rot = targets[count].eulerAngles - this.transform.eulerAngles;
            this.transform.position += dir * speed * Time.deltaTime;
            this.transform.Rotate(rot * speed * Time.deltaTime);
            if(count<targets.Length-1)
                RotateDiamonds(count);
            else
            {
                //set camera to main view and disable gravity
                for(int i = 0; i < gameObjects.Length; i++)
                {
                    gameObjects[i].transform.position = origins[i].transform.position;
                    gameObjects[i].transform.rotation = origins[i].transform.rotation;
                    rigidbodies[i].useGravity = false;
                }
            }
        }
    }
    void RotateDiamonds(int i)
    {
        if (i > gameObjects.Length - 1)
            return;
        rigidbodies[i].useGravity = false;
        rigidbodies[i].isKinematic = true;

        //gameObjects[i].transform.position = new Vector3(gameObjects[i].transform.position.x, 1.5f, gameObjects[i].transform.position.z);
        gameObjects[i].transform.position = origins[i].transform.position;
        gameObjects[i].transform.Rotate(Vector3.forward * rotateSpeed * Time.deltaTime);
    }
}
