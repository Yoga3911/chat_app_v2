class UserModel {
    UserModel({
        required this.id,
        required this.username,
        required this.email,
        required this.password,
        required this.image,
        required this.isActive,
    });

    final String id;
    final String username;
    final String email;
    final String password;
    final String image;
    final bool isActive;

    factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json["id"],
        username: json["username"],
        email: json["email"],
        password: json["password"],
        image: json["image"],
        isActive: json["isActive"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "email": email,
        "password": password,
        "image": image,
        "isActice": isActive,
    };
}
