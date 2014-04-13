$ ->
  $(".like-button").on "click", ->
    value = if $(this).hasClass("active") then 0 else 1
    $.ajax({
      type: "post",
      url: "post_like/update",
      data:
        post_id: $(this).data("post-id"),
        value: value
    }).error ->
      alert("Error sending like")