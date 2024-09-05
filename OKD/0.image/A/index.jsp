<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Full-Screen Image</title>
    <style>
        body, html {
            height: 100%;
            margin: 0;
        }
        .bg-image {
            /* The image used */
            background-image: url("image1.png");

            /* Full height */
            height: 100%;

            /* Center and scale the image */
            background-position: center;
            background-size: contain;
            background-repeat: no-repeat;
        }
    </style>
</head>
<body>
    <div class="bg-image"></div>
</body>
</html>
