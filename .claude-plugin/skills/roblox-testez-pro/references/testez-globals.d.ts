/// <reference types="@rbxts/testez/globals" />

declare global {
    interface _G {
        /**
         * 仅供 testez cloud 调试使用, 调试完毕后必须删除.
         * @param args 
         * @returns 
         */
        print: (...args: any[]) => void
    }
}

export {};