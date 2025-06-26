/* PROFILE UPDATE FORMS (SELF) */
$(document).ready(function() {

    // Add jQuery validation default styling
    $.validator.setDefaults({
        highlight: function(element) {
            $(element)
                .addClass('border-red-500')
                .removeClass('border-gray-200')
                .removeClass('focus:ring-indigo-400')
                .addClass('ring-2')
                .addClass('ring-red-200');
        },
        unhighlight: function(element) {
            $(element)
                .removeClass('border-red-500')
                .addClass('border-gray-200')
                .addClass('focus:ring-indigo-400')
                .removeClass('ring-2')
                .removeClass('ring-red-200');
        }
    });

    // Loging Form Validation
    const loginValidator = $("#loginForm").validate({
        errorClass: "error",
        errorElement: "span",
        highlight: function(element) {
            $(element)
                .removeClass('border-gray-200')
                .removeClass('focus:outline-indigo-600')
                .addClass('border-red-500')
                .addClass('ring-2')
                .addClass('ring-red-200')
                .addClass('focus:outline-red-600')
                .addClass('outline-red-300');
        },
        unhighlight: function(element) {
            $(element)
                .addClass('border-gray-200')
                .addClass('focus:outline-indigo-600')
                .removeClass('border-red-500')
                .removeClass('ring-2')
                .removeClass('ring-red-200')
                .removeClass('focus:outline-red-600')
                .removeClass('outline-red-300');
        },
        errorPlacement: function(error, element) {
            error.insertAfter(element.parent());
        },
        rules: {
            email: {
                required: true,
                email: true,
            },
            password: {
                required: true,
                minlength: 8
            }
        },
        messages: {
            email: {
                required: "Please enter your email address",
                email: "Please enter a valid email address",
            },
            password: {
                required: "Please enter your password",
                minlength: "Your password must be at least 8 characters long"
            }
        }
    });

    // Form validation
    $('#forgotPasswordForm').validate({
        rules: {
            newPassword: {
                required: true,
                minlength: 8
            },
            confirmPassword: {
                required: true,
                equalTo: '#newPassword'
            }
        },
        messages: {
            newPassword: {
                required: 'Please enter a new password',
                minlength: 'Password must be at least 8 characters'
            },
            confirmPassword: {
                required: 'Please confirm your password',
                equalTo: 'Passwords do not match'
            }
        },
        submitHandler: function(form) {
            const formData = {
                email: $('#email').val(),
                newPassword: $('#newPassword').val()
            };

            $.ajax({
                url: $(form).attr('action'),
                method: 'POST',
                data: formData,
                success: function(response) {
                    if (response.status === 'success') {
                        Swal.fire({
                            icon: 'success',
                            title: 'Success!',
                            text: 'Your password has been reset',
                            confirmButtonColor: "#52b855"
                        }).then(() => {
                            window.location.href = 'index.php';
                        });
                    } else {
                        Swal.fire({
                            icon: 'error',
                            title: 'Error',
                            text: response.message,
                            confirmButtonColor: "#d32f2f"
                        });
                    }
                }
            });
        }
    });

    // Profile Picture Upload
    $('#uploadNew').click(function() {
        $('#profilePicture').click();
    });

    $('#profilePicture').change(function(e) {
        const file = e.target.files[0];
        if (file) {
            // Validate file type
            const validTypes = ['image/jpeg', 'image/png', 'image/gif'];
            if (!validTypes.includes(file.type)) {
                Swal.fire({
                    icon: 'error',
                    title: 'Invalid File Type',
                    text: 'Please upload an image file (JPEG, PNG, or GIF)',
                    confirmButtonColor: "#d32f2f",
                    timer: 1000
                });
                return;
            }

            // Validate file size (max 5MB)
            if (file.size > 5 * 1024 * 1024) {
                Swal.fire({
                    icon: 'error',
                    title: 'File Too Large',
                    text: 'Please upload an image smaller than 5MB',
                    confirmButtonColor: "#d32f2f",
                    timer: 1000
                });
                return;
            }

            // Upload file
            const formData = new FormData();
            formData.append('profile_picture', file);

            $.ajax({
                url: '../php/account/update_self_account.php',
                type: 'POST',
                data: formData,
                processData: false,
                contentType: false,
                success: function(response) {
                    if (response.status === 'success') {
                        // Update preview
                        const reader = new FileReader();
                        reader.onload = function(e) {
                            $('.profile-picture').attr('src', e.target.result);
                        }
                        reader.readAsDataURL(file);

                        Swal.fire({
                            icon: 'success',
                            title: 'Success!',
                            text: response.message,
                            confirmButtonColor: "#52b855",
                            timer: 1000
                        });
                    } else {
                        Swal.fire({
                            icon: 'error',
                            title: 'Error',
                            text: response.message,
                            confirmButtonColor: "#d32f2f",
                            timer: 1000
                        });
                    }
                },
                error: function() {
                    Swal.fire({
                        icon: 'error',
                        title: 'Error',
                        text: 'Failed to upload profile picture',
                        confirmButtonColor: "#d32f2f",
                        timer: 1000
                    });
                }
            });
        }
    });

    $.validator.addMethod("validContact", function(value, element) {
        return this.optional(element) || (value.length === 11 && value.startsWith("09"));
    }, "Contact number must be valid");

    // Basic Information Form Validation
    const profileValidator = $("#profileForm").validate({
        rules: {
            firstName: {
                required: true,
                minlength: 2
            },
            middleName: {
                minlength: 2,
            },
            lastName: {
                required: true,
                minlength: 2
            },
            email: {
                required: true,
                email: true,
            }
        },
        messages: {
            firstName: {
                required: "Please enter your first name",
                minlength: "First name must be at least 2 characters long"
            },
            middleName: {
                // required: "Please enter your middle name",
                minlength: "Middle name must be at least 2 characters long"
            },
            lastName: {
                required: "Please enter your last name",
                minlength: "Last name must be at least 2 characters long"
            },
            email: {
                required: "Please enter your email address",
                email: "Please enter a valid email address",
            }
        }
    });

    // More Information Form Validation
    const moreInfoValidator = $("#moreInfoForm").validate({
        rules: {
            phone: {
                required: true,
                minlength: 11,
                maxlength: 11,
                digits: true,
                validContact: true
            },
            location: {
                required: true,
                minlength: 5
            },
            role: {
                required: true,
                minlength: 2
            },
            website: {
                url: true,
                required: true
            }
        },
        messages: {
            phone: {
                required: "Please enter your phone number",
                minlength: "Phone number must be 11 digits",
                maxlength: "Phone number must be 11 digits",
                digits: "Please enter only digits",
                validContact: "Contact number must be valid."            
            },
            location: {
                required: "Please enter your address",
                minlength: "Address must be at least 5 characters long"
            },
            role: {
                required: "Please enter your role",
                minlength: "Role must be at least 2 characters long"
            },
            website: {
                required: "Please enter your website URL",
                url: "Please enter a valid URL"
            }
        }
    });

    // Change Password Form Validation
    const passwordChangeValidator = $("#changePasswordForm").validate({
        errorClass: "error",
        errorElement: "span",
        highlight: function(element) {
            $(element)
                .addClass('border-red-500')
                .removeClass('border-gray-200')
                .removeClass('focus:ring-indigo-400')
                .addClass('ring-2')
                .addClass('ring-red-200');
        },
        unhighlight: function(element) {
            $(element)
                .removeClass('border-red-500')
                .addClass('border-gray-200')
                .addClass('focus:ring-indigo-400')
                .removeClass('ring-2')
                .removeClass('ring-red-200');
        },
        errorPlacement: function(error, element) {
            error.insertAfter(element.parent());
        },
        rules: {
            currentPassword: {
                required: true // Ensure the old password is required
            },
            newPassword: {
                required: true,
                minlength: 8,
                // mypassword: true
            },
            confirmPassword: {
                required: true,
                equalTo: "#newPassword" // Ensure the confirm password matches the new password
            }
        },
        messages: {
            currentPassword: {
                required: "Please enter your old password"
            },
            newPassword: {
                required: "Please enter a new password",
                minlength: "Your password must be at least 8 characters long"
            },
            confirmPassword: {
                required: "Please confirm your new password",
                equalTo: "Passwords do not match"
            }
        }
    });

    const createAccountValidator = $("#createAccountForm").validate({
        rules: {
            first_name: {
                required: true,
                minlength: 2
            },
            middle_name: {
                minlength: 2
            },
            last_name: {
                required: true,
                minlength: 2
            },
            contact_no: {
                required: true,
                minlength: 11,
                maxlength: 11,
                digits: true,
                validContact: true
            },
            email: {
                required: true,
                email: true
            },
            role: {
                required: true
            },
            address: {
                required: true
            },
            profile_picture: {
                fileTypeAndSize: true // Using the custom method defined in accounts.php
            }
        },
        messages: {
            first_name: {
                required: "Please enter the first name",
                minlength: "First name must be at least 2 characters long"
            },
            middle_name: {
                 minlength: "Middle name must be at least 2 characters long"
            },
            last_name: {
                required: "Please enter the last name",
                minlength: "Last name must be at least 2 characters long"
            },
            contact_no: {
                required: "Please enter the contact number",
                minlength: "Contact number must be 11 digits",
                maxlength: "Contact number must be 11 digits",
                digits: "Please enter only digits",
                validContact: "Contact number must start with 09 and be 11 digits."
            },
            email: {
                required: "Please enter the email address",
                email: "Please enter a valid email address"
            },
            role: {
                required: "Please select a role"
            },
            address: {
                required: "Please select an address"
            }
        }
    });
    
    // Store both validators globally
    window.formValidators = {
        loginForm: loginValidator,
        profileForm: profileValidator,
        moreInfoForm: moreInfoValidator,
        changePasswordForm: passwordChangeValidator,
        createAccountForm: createAccountValidator,
    };

    // Save field changes
    // window.saveField = function(field) {
    //     const input = $(`#${field}`);
    //     const value = input.val().trim();
        
    //     if (!value) {
    //         Swal.fire({
    //             icon: 'error',
    //             title: 'Error',
    //             text: 'Field cannot be empty',
    //             confirmButtonColor: "#d32f2f",
    //             timer: 1000
    //         });
    //         return;
    //     }
    
    //     const formData = new FormData();
    //     formData.append(field, value);
    
    //     $.ajax({
    //         url: '../php/account/update_self_account.php',
    //         type: 'POST',
    //         data: formData,
    //         processData: false,
    //         contentType: false,
    //         success: function(response) {
    //             if (response.status === 'success') {
    //                 // Update all field values immediately
    //                 input.val(value);
    //                 input.attr('data-original-value', value);
    //                 input.prop('defaultValue', value);
                    
    //                 // Update display
    //                 input.attr('readonly', true).addClass('bg-gray-50');
    //                 $(`#${field}-actions`).addClass('hidden');
    
    //                 Swal.fire({
    //                     icon: 'success',
    //                     title: 'Success!',
    //                     text: response.message,
    //                     confirmButtonColor: "#52b855",
    //                     timer: 1000,
    //                 });
    //             } else {
    //                 Swal.fire({
    //                     icon: 'error',
    //                     title: 'Error',
    //                     text: response.message || 'Failed to update field',
    //                     confirmButtonColor: "#d32f2f",
    //                     timer: 1000
    //                 });
    //             }
    //         },
    //         error: function() {
    //             Swal.fire({
    //                 icon: 'error',
    //                 title: 'Error',
    //                 text: 'Failed to update field',
    //                 confirmButtonColor: "#d32f2f",
    //                 timer: 1000
    //             });
    //         }
    //     });
    // };
    
});