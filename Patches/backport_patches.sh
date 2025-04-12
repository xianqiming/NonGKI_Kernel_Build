#!/bin/bash
# Patches author: backslashxx @Github
# Shell authon: JackA1ltman <cs2dtzq@163.com>
# Tested kernel versions: 5.4, 4.19, 4.14, 4.9, 4.4
# 20250323
patch_files=(
    fs/namespace.c
    fs/internal.h
    kernel/cred.c
    include/linux/cred.h
    include/linux/uaccess.h
    mm/maccess.c
)

for i in "${patch_files[@]}"; do

    if grep -q "path_umount" "$i"; then
        echo "Warning: $i contains KernelSU"
        continue
    elif grep -q "get_cred_rcu" "$i"; then
        echo "Warning: $i contains KernelSU"
        continue
    elif grep -q "strncpy_from_user_nofault" "$i"; then
        echo "Warning: $i contains KernelSU"
        continue
    fi

    case $i in

    # fs/ changes
    ## fs/namespace.c
    fs/namespace.c)
        if grep -q "static inline bool may_mandlock(void)" fs/namespace.c; then
            sed -i '/^static bool is_mnt_ns_file/i static int can_umount(const struct path *path, int flags)\n\{\n\tstruct mount *mnt = real_mount(path->mnt);\n\tif (flags & ~(MNT_FORCE | MNT_DETACH | MNT_EXPIRE | UMOUNT_NOFOLLOW))\n\t\treturn -EINVAL;\n\tif (!may_mount())\n\t\treturn -EPERM;\n\tif (path->dentry != path->mnt->mnt_root)\n\t\treturn -EINVAL;\n\tif (!check_mnt(mnt))\n\t\treturn -EINVAL;\n\tif (mnt->mnt.mnt_flags & MNT_LOCKED)\n\t\treturn -EINVAL;\n\tif (flags & MNT_FORCE && !capable(CAP_SYS_ADMIN))\n\t\treturn -EPERM;\n\treturn 0;\n}\n' fs/namespace.c
            sed -i '/^static bool is_mnt_ns_file/i int path_umount(struct path *path, int flags)\n{\n\tstruct mount *mnt = real_mount(path->mnt);\n\tint ret;\n\tret = can_umount(path, flags);\n\tif (!ret)\n\t\tret = do_umount(mnt, flags);\n\tdput(path->dentry);\n\tmntput_no_expire(mnt);\n\treturn ret;\n}\n' fs/namespace.c
        else
            sed -i '/SYSCALL_DEFINE2(umount, char __user \*, name, int, flags)/i\#ifdef CONFIG_KSU\nstatic int can_umount(const struct path *path, int flags)\n{\n\tstruct mount *mnt = real_mount(path->mnt);\n\n\tif (flags & ~(MNT_FORCE | MNT_DETACH | MNT_EXPIRE | UMOUNT_NOFOLLOW))\n\t\treturn -EINVAL;\n\tif (!may_mount())\n\t\treturn -EPERM;\n\tif (path->dentry != path->mnt->mnt_root)\n\t\treturn -EINVAL;\n\tif (!check_mnt(mnt))\n\t\treturn -EINVAL;\n\tif (mnt->mnt.mnt_flags & MNT_LOCKED) /* Check optimistically */\n\t\treturn -EINVAL;\n\tif (flags & MNT_FORCE && !capable(CAP_SYS_ADMIN))\n\t\treturn -EPERM;\n\treturn 0;\n}\n\nint path_umount(struct path *path, int flags)\n{\n\tstruct mount *mnt = real_mount(path->mnt);\n\tint ret;\n\n\tret = can_umount(path, flags);\n\tif (!ret)\n\t\tret = do_umount(mnt, flags);\n\n\t/* we mustn'\''t call path_put() as that would clear mnt_expiry_mark */\n\tdput(path->dentry);\n\tmntput_no_expire(mnt);\n\treturn ret;\n}\n#endif\n' fs/namespace.c
        fi
        ;;
    ## fs/internal.h
    fs/internal.h)
        KERNEL_VERSION=$(head -n 3 Makefile | grep -E 'VERSION|PATCHLEVEL' | awk '{print $3}' | paste -sd '.')
        CHECK_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $2}')
        if [ "$CHECK_VERSION" -le 9 ]; then
            if grep -q "extern void __mnt_drop_write(struct vfsmount \*)" fs/internal.h; then
                sed -i '/extern void __mnt_drop_write_file(struct file \*);/a int path_umount(struct path \*path, int flags);' fs/internal.h
            else
                sed -i '/^extern void __init mnt_init/a int path_umount(struct path *path, int flags);' fs/internal.h
            fi
        fi
        ;;

    # kernel/ changes
    ## kernel/cred.c
    kernel/cred.c)
        if grep -q "atomic_long_inc_not_zero" kernel/cred.c; then
            sed -i "s/!atomic_long_inc_not_zero(&((struct cred \*)cred)->usage)/!get_cred_rcu(cred)/g" kernel/cred.c
        else
            sed -i "s/!atomic_inc_not_zero(&((struct cred \*)cred)->usage)/!get_cred_rcu(cred)/g" kernel/cred.c
        fi
        ;;

    # include/ changes
    ## include/linux/cred.h
    include/linux/cred.h)
        if grep -q "atomic_long_inc_not_zero" include/linux/cred.h; then
            sed -i '/^static inline void put_cred/i static inline const struct cred *get_cred_rcu(const struct cred *cred)\n{\n\tstruct cred *nonconst_cred = (struct cred *) cred;\n\tif (!cred)\n\t\treturn NULL;\n\tif (!atomic_long_inc_not_zero(&nonconst_cred->usage))\n\t\treturn NULL;\n\tvalidate_creds(cred);\n\treturn cred;\n\}\n' include/linux/cred.h
        else
            sed -i '/^static inline void put_cred/i static inline const struct cred *get_cred_rcu(const struct cred *cred)\n{\n\tstruct cred *nonconst_cred = (struct cred *) cred;\n\tif (!cred)\n\t\treturn NULL;\n\tif (!atomic_inc_not_zero(&nonconst_cred->usage))\n\t\treturn NULL;\n\tvalidate_creds(cred);\n\treturn cred;\n\}\n' include/linux/cred.h
        fi
        ;;
    ## include/linux/uaccess.h
    include/linux/uaccess.h)
        sed -i 's/^extern long strncpy_from_unsafe_user/long strncpy_from_user_nofault/' include/linux/uaccess.h
        ;;

    # mm/ changes
    ## mm/maccess.c
    mm/maccess.c)
        sed -i 's/\* strncpy_from_unsafe_user: - Copy a NUL terminated string from unsafe user/\* strncpy_from_user_nofault: - Copy a NUL terminated string from unsafe user/' mm/maccess.c
        sed -i 's/long strncpy_from_unsafe_user(char \*dst, const void __user \*unsafe_addr,/long strncpy_from_user_nofault(char *dst, const void __user *unsafe_addr,/' mm/maccess.c
        ;;
    esac

done
