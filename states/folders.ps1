 $folders = @(
        
            "stage\vpc",
            "stage\vpc\services",
            "stage\vpc\services\front-end-app",
            "stage\vpc\services\back-end-app",
            "stage\vpc\data-storage\mysql",
            "stage\vpc\data-storage\redis"   

            "prod\vpc",
            "prod\vpc\services",
            "prod\vpc\services\front-end-app",
            "prod\vpc\services\back-end-app",
            "prod\vpc\data-storage\mysql",
            "prod\vpc\data-storage\redis"
            
            "mgmt\vpc",
            "mgmt\vpc\services",
            "mgmt\vpc\services\front-end-app",
            "mgmt\vpc\services\back-end-app",
            "mgmt\vpc\data-storage\mysql"
            "mgmt\vpc\data-storage\redis",

            "global\iam",
            "global\s3"
            
            )

foreach ($folder in $folders) {

New-Item -Path $folder -ItemType Directory -Force
    
}