import type { TurboModule } from "react-native";
import { TurboModuleRegistry } from "react-native";

export interface Spec extends TurboModule {
  setText(text: string): void;
  getConstants(): {
    darkModeEnabled: boolean;
    logoSizeRatio?: number;
    navigationBarHeight?: number;
    statusBarHeight?: number;
    currentText?: string;
  };
  hide(fade: boolean): Promise<void>;
  isVisible(): Promise<boolean>;
}

export default TurboModuleRegistry.getEnforcing<Spec>("RNBootSplash");
